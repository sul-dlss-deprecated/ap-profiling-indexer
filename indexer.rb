# external gems
require 'confstruct'
require 'harvestdor'
require 'rsolr'
# stdlib
require 'logger'
require 'open-uri'

# local files
require 'sax_profiling_document'
require 'ap_tei_profiling_document'

# Base class to harvest from DOR via harvestdor gem
class Indexer

  def initialize yml_path, options = {}
    @yml_path = yml_path
    config.configure(YAML.load_file(yml_path)) if yml_path    
    config.configure options 
    yield(config) if block_given?
  end
  
  def config
    @config ||= Confstruct::Configuration.new()
  end

  def logger
    @logger ||= load_logger(config.log_dir, config.log_name)
  end
  
  # value for collection field
  #   will be populated from config.coll_fld_val 
  #   will be the config.default_set if there is no config.coll_fld_val
  def collection
    @collection = config.coll_fld_val ? config.coll_fld_val : config.default_set
  end
  
  # per this Indexer's config options 
  #  harvest the druids via OAI
  #   create Solr profiling documents for each druid
  #   write the result to the Solr index
  def harvest_and_index
    if whitelist.empty?
      druids.each { |druid| profile druid }
    else
      whitelist.each { |druid| profile druid }
    end
    logger.info("Finished processing: final Solr commit returned.")
  end
  
  # return Array of druids contained in the OAI harvest indicated by OAI params in yml configuration file
  # @return [Array<String>] or enumeration over it, if block is given.  (strings are druids, e.g. ab123cd1234)
  def druids
    @druids ||= harvestdor_client.druids_via_oai
  end
    
  # get the AP volume "number" from the identityMetadata in the public_xml for the druid
  # @param [String] druid we are seeking the volume number for this druid
  # @return [String] the volume number for the druid, per the identity from the public_xml
  def volume druid
    im = harvestdor_client.identity_metadata(druid)
    im.root.xpath('objectLabel').text
  end
  
  # get the TEI for the AP volume via the digital stacks.  
  # @return [String] the TEI as a String
  def tei druid
    url = "#{config.stacks}/file/druid:#{druid}/#{druid}.xml"
    open(url)
  rescue Exception => e
    logger.error("error while retrieving tei at #{url} -- #{e.message}")
    "<TEI.2/>"
  end
  
  def solr_client
    @solr_client ||= RSolr.connect(config.solr.to_hash)
  end

  # @return an Array of druids ('oo000oo0000') that should NOT be processed
  def blacklist
    # avoid trying to load the file multiple times
    if !@blacklist && !@loaded_blacklist
      @blacklist = load_blacklist(config.blacklist) if config.blacklist
    end
    @blacklist ||= []
  end
  
  # @return an Array of druids ('oo000oo0000') that should NOT be processed
  def whitelist
    # avoid trying to load the file multiple times
    if !@whitelist && !@loaded_whitelist
      @whitelist = load_whitelist(config.whitelist) if config.whitelist
    end
    @whitelist ||= []
  end
  
  protected #---------------------------------------------------------------------

  def harvestdor_client
    @harvestdor_client ||= Harvestdor::Client.new({:config_yml_path => @yml_path})
  end
  
  # create Solr doc for the druid and add it to Solr, unless it is on the blacklist.  
  #  NOTE: no Solr commit performed
  def profile druid
    if blacklist.include?(druid)
      logger.info("Druid #{druid} is on the blacklist and will not be processed")
    else
      vol = volume(druid)
#       spd = SaxProfilingDocument.new(solr_client, druid, vol, collection, logger)
      spd = ApTeiProfilingDocument.new(solr_client, druid, vol, collection, logger)
      parser = Nokogiri::XML::SAX::Parser.new(spd)
      tei_xml = tei(druid)
      logger.info("About to parse #{druid} (#{vol})")
      parser.parse(tei_xml)
      logger.info("Finished parsing #{druid}")
      solr_client.commit
      logger.info("Sent commit to Solr")
      # TODO: update DOR object's workflow datastream??
    end
  end
  

  # Global, memoized, lazy initialized instance of a logger
  # @param String directory for to get log file
  # @param String name of log file
  def load_logger(log_dir, log_name)
    Dir.mkdir(log_dir) unless File.directory?(log_dir) 
    @logger ||= Logger.new(File.join(log_dir, log_name), 'daily')
  end
    
  # populate @blacklist as an Array of druids ('oo000oo0000') that will NOT be processed
  #  by reading the File at the indicated path
  # @param path - path of file containing a list of druids
  def load_blacklist path
    if path && !@loaded_blacklist
      @loaded_blacklist = true
      @blacklist = load_id_list path
    end
  end
    
  # populate @blacklist as an Array of druids ('oo000oo0000') that WILL be processed
  #  (unless a druid is also on the blacklist)
  #  by reading the File at the indicated path
  # @param path - path of file containing a list of druids
  def load_whitelist path
    if path && !@loaded_whitelist
      @loaded_whitelist = true
      @whitelist = load_id_list path
    end
  end
    
  # return an Array of druids ('oo000oo0000')
  #   populated by reading the File at the indicated path
  # @param path - path of file containing a list of druids
  # @return an Array of druids
  def load_id_list path
    if path 
      list = []
      f = File.open(path).each_line { |line|
        list << line.gsub(/\s+/, '') if !line.gsub(/\s+/, '').empty?
      }
      list
    end
  rescue
    msg = "Unable to find list of druids at " + path
    logger.fatal msg
    raise msg
  end

end
