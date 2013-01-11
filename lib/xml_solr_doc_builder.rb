require 'logger'

# Class to build the Hash representing a Solr document for a particular Nokogiri XML document
class XmlSolrDocBuilder

  attr_reader :logger

  # @param [Logger] logger for indexing messages
  def initialize(logger = Logger.new(STDOUT))
    @logger = logger
  end
  
  # for each element in this nokogiri document, create key-value pairs:
  #   element_name => text value of all element children
  #   for each attribute of element:
  #      element_name_attribute_name => value of attribute  (??not multivalued! ??)
  #   for each element child of element, the same as above, preceded by parent el
  #      parent_el_name_child_el_name => text value of all child element children ...
  # @param [Nokogiri::XML::Document] ng_doc 
  # @return [Hash<Symbol, Array<String>>] Hash representation of the Solr fields
  def doc_hash(ng_doc)
    doc_hash_from_element ng_doc.root
  end
    
  # Create Hash representation of Solr fields for this element and its attribute and element children.
  # @param [Nokogiri::XML::Element] ng_el
  # @return [Hash<Symbol, Array<String>>] Hash representation of the Solr fields for this element
  def doc_hash_from_element ng_el
    el_name = ng_el.name
    hash = {}
    # field for element text content  (FIXME: cdata vs text?)
    el_text = ng_el.text.gsub(/\s+/,' ').strip
    hash[el_name.to_sym] = el_text unless el_text.empty?
    # field for each element attribute
    ng_el.attribute_nodes.each { |an|  
      at_text = an.text.strip
      if an.namespace
        hash["#{el_name}_#{an.namespace.prefix}_#{an.name}".to_sym] = at_text  unless at_text.empty?
      else
        hash["#{el_name}_#{an.name}".to_sym] = at_text  unless at_text.empty?
      end
    }
    # recurse for subelements
    hash
  end
    
end # XmlSolrDocBuilder class