require 'nokogiri'
require 'logger'

# Subclass SaxProfilingDocument, which is a subclass of Nokogiri::XML::SAX::Document for 
#  streaming parsing of xml for profiling purposes
class ApProfilingDocument < SaxProfilingDocument

  # @param [RSolr::Client] rsolr_client used to write the Solr documents as we build them
  # @param [String] druid the druid for the DOR object that contains this TEI doc
  # @param [String] volume the volume number (it might not be a strict number string, e.g. '71B')
  # @param [Logger] logger to receive logged messages
  def initialize (rsolr_client, druid, volume, logger)
    super(rsolr_client, druid, volume, logger)
    @ignore_elements = ['pb', 'item']
  end

end # ApProfilingDocument