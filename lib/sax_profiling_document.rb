require 'nokogiri'

# Subclass of Nokogiri::XML::SAX::Document for 
#  streaming parsing of xml for profiling purposes
# borrows heavily from sax-machine's sax_handler
#   https://github.com/pauldix/sax-machine/blob/master/lib/sax-machine/sax_handler.rb
class SaxProfilingDocument < Nokogiri::XML::SAX::Document
  
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
    chars = data.strip.gsub(/\s+/, ' ')
    # add chars to node buffer for stack
    @stack.reverse.each { |snode|  
      if snode.buffer == NO_BUFFER
        snode.buffer = chars.dup
      else
        snode.buffer << ' ' + chars.dup
      end
    }
  end
  alias cdata_block characters
  
  # @param [String] name the element tag
  # @param [Array<String>] attributes an assoc list of namespaces and attributes, e.g.:
  #     [ ["xmlns:foo", "http://sample.net"], ["size", "large"] ]
  def start_element name, attributes
    @stack.push(StackNode.new(name.sub(':', '_')))
    attributes.each { |pair|  
      att_name = pair[0].sub(':', '_')
      att_val = pair[1]
      unless att_name.start_with?('xmlns')
        add_to_doc_hash("#{name}_#{att_name}", [att_val]) unless att_val.strip.empty?
      end
    }
  end
  
  # @param [String] name the element tag
  def end_element name
    node = @stack.pop
    text = node.buffer
    # add buffer to values for THIS node
    if text != NO_BUFFER
      node.values << text.strip.gsub(/\s+/, ' ') unless text.strip.gsub(/\s+/, ' ').size <= 1
    end
    unless node.values.empty?
      # write to doc_hash for THIS node
      add_to_doc_hash(node.name, node.values)
      # write to doc_hash for other nodes in the stack
      suffix = "_#{node.name}"
      stack_names.reverse.each { |sname| 
        k = "#{sname}#{suffix}"
        add_to_doc_hash(k, node.values)
        suffix = "_#{sname}" + suffix
      }
    end
  end
  
  # --------- Not part of the Nokogiri::XML::SAX::Document events -----------------
    
  attr_reader :doc_hash

  NO_BUFFER = :no_buffer
  
  class StackNode < Struct.new(:name, :buffer, :values)
    def initialize(name, buffer = NO_BUFFER, values = [])
      self.name = name
      self.buffer = buffer
      self.values = values
    end
  end
  
  # add the values to the doc_hash for the Solr field.
  # @param [String] key the Solr field base name (no dynamic field suffix), as a String
  # @param [Array<String>] values the values to add to the doc_hash for the key
  def add_to_doc_hash(key, values)
    k = "#{key}_sim".to_sym
    if @doc_hash[k]
      @doc_hash[k].concat(values.dup) 
    else
      @doc_hash[k] = values.dup
    end
  end

  # @return [Array<String>] the names of the StackNodes currently in @stack, in Array order
  def stack_names
    names = []
    @stack.each { |node|  
      names << node.name
    }
    names
  end

end # ApTeiDocument class
