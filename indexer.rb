# external gems
require 'confstruct'
require 'harvestdor'
require 'rsolr'
# stdlib
require 'logger'
require 'open-uri'

# local files
require 'sax_profiling_document'

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
  #   create a Solr document for each druid suitable for SearchWorks
  #   write the result to the SearchWorks Solr index
  def harvest_and_index
    druids.each { |druid|  
      vol = volume(druid)
      spd = SaxProfilingDocument.new(solr_client, druid, vol, collection, logger)
      parser = Nokogiri::XML::SAX::Parser.new(spd)
      tei_xml = tei(druid)
      parser.parse(tei_xml)
    }
    solr_client.commit
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

  protected #---------------------------------------------------------------------

  def harvestdor_client
    @harvestdor_client ||= Harvestdor::Client.new({:config_yml_path => @yml_path})
  end
  
  # Global, memoized, lazy initialized instance of a logger
  # @param String directory for to get log file
  # @param String name of log file
  def load_logger(log_dir, log_name)
    Dir.mkdir(log_dir) unless File.directory?(log_dir) 
    @logger ||= Logger.new(File.join(log_dir, log_name), 'daily')
  end
    
end