require 'nokogiri'

# Subclass of Nokogiri::XML::SAX::Document for 
#  streaming parsing of xml for profiling purposes
# borrows heavily from sax-machine's sax_handler
#   https://github.com/pauldix/sax-machine/blob/master/lib/sax-machine/sax_handler.rb
class SaxProfilingDocument < Nokogiri::XML::SAX::Document
  
  attr_reader :doc_hash

  NO_BUFFER = :no_buffer
  
  class StackNode < Struct.new(:name, :buffer, :values)
    def initialize(name, buffer = NO_BUFFER, values = [])
      self.name = name
      self.buffer = buffer
      self.values = values
    end
  end

  # @param [RSolr::Client] rsolr_client used to write the Solr documents as we build them
  # @param [String] druid the druid for the DOR object that contains this TEI doc
  # @param [String] volume the volume number (it might not be a strict number string, e.g. '71B')
  def initialize (rsolr_client, druid, volume)
    @rsolr_client = rsolr_client
    @druid = druid
    @volume = volume
  end
  
  def start_document
    @stack = []
    @doc_hash = {}
    @doc_hash[:druid] = @druid
    @doc_hash[:volume_ssi] = @volume
  end
  
  def end_document
    @rsolr_client.add(@doc_hash)
  end
    
  # Characters read between a tag.  This method might be called multiple
  # times given one contiguous string of characters.
  #
  # @param [String] data contains the character data
  def characters(data)
    # current node
    node = @stack.last
    chars = data.strip.gsub(/\s+/,' ')
    if node.buffer == NO_BUFFER
      node.buffer = chars.dup
    else
      node.buffer << chars
    end
  end
  alias cdata_block characters
  
  # @param [String] name the element tag
  # @param [Array<String>] attributes an assoc list of namespaces and attributes, e.g.:
  #     [ ["xmlns:foo", "http://sample.net"], ["size", "large"] ]
  def start_element name, attributes
    @stack.push(StackNode.new(name))
# TODO: append name on each element in stack
  end
  
  # @param [String] name the element tag
  def end_element name
    node = @stack.pop
    text = node.buffer
    if text != NO_BUFFER
      # for THIS node
      node.values << text
      # for other nodes in the stack
      @stack.each { |snode|
        snode.values << text
      }
    end
    k = node.name.to_sym
    if @doc_hash[k]
      @doc_hash[k].concat(node.values)
    else
      @doc_hash[k] = node.values
    end
  end
  
  # --------- Not part of the Nokogiri::XML::SAX::Document events -----------------
    
end # ApTeiDocument class
