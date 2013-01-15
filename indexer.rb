# external gems
require 'confstruct'
require 'harvestdor'
require 'rsolr'
# stdlib
require 'logger'

# local files
require 'solr_doc_builder'

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
  
  # per this Indexer's config options 
  #  harvest the druids via OAI
  #   create a Solr document for each druid suitable for SearchWorks
  #   write the result to the SearchWorks Solr index
  def harvest_and_index
    druids.each { |id|  
      solr_client.add(solr_doc(id))
      # update DOR object's workflow datastream??   for harvest?  for indexing?
    }
    solr_client.commit
  end
  
  # return Array of druids contained in the OAI harvest indicated by OAI params in yml configuration file
  # @return [Array<String>] or enumeration over it, if block is given.  (strings are druids, e.g. ab123cd1234)
  def druids
    @druids ||= harvestdor_client.druids_via_oai
  end

  # Create a Solr doc, as a Hash, to be added to the SearchWorks Solr index.  
  # Solr doc contents are based on the mods, contentMetadata, etc. for the druid
  # @param [String] druid, e.g. ab123cd4567
  # @param [Stanford::Mods::Record] MODS metadata as a Stanford::Mods::Record object
  # @param [Hash] Hash representing the Solr document
  def solr_doc druid
    sdb = SolrDocBuilder.new(druid, harvestdor_client, logger)
    doc_hash = sdb.doc_hash
    doc_hash[:collection] = config.coll_fld_val ? config.coll_fld_val : config.default_set

    # add things from Indexer level class (info kept here for caching purposes)
    doc_hash
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