require 'nokogiri'
require 'logger'

# Subclass of SaxProfilingDocument for Archives Parlementaire TEI documents
# 
# SaxProfilingDocument is a subclass of Nokogiri::XML::SAX::Document for 
#  streaming parsing of xml for profiling purposes
class ApTeiProfilingDocument < SaxProfilingDocument

  # @param [RSolr::Client] rsolr_client used to write the Solr documents as we build them
  # @param [String] druid the druid for the DOR object that contains this TEI doc
  # @param [String] volume the volume number (it might not be a strict number string, e.g. '71B')
  # @param [String] collection the string to  (it might not be a strict number string, e.g. '71B')
  # @param [Logger] logger to receive logged messages
  def initialize (rsolr_client, druid, volume, collection, logger)
    super(rsolr_client, druid, volume, collection, logger)
    @ignore_elements = ['pb', 'p', 'item',
      'teiHeader','fileDesc','notesStmt','publicationStmt','distributor','address','addrLine','pubPlace','titleStmt','author','title',
      'front','div','titlePage','docAuthor','name','docTitle','titlePart',      
      ] 
    @outer_elements_to_ignore = ['TEI.2', 'text']
  end

end # ApTeiProfilingDocument
