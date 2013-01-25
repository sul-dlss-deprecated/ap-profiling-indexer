# encoding: utf-8
require "spec_helper"

describe SaxProfilingDocument do
  before(:all) do
    @coll = 'archives'
    @volume = '36'
    @druid = 'aa222bb4444'
    @rsolr_client = RSolr::Client.new('http://somewhere.org')
    @logger = Logger.new(STDOUT)
    @atd = SaxProfilingDocument.new(@rsolr_client, @druid, @volume, @coll, @logger)
    @parser = Nokogiri::XML::SAX::Parser.new(@atd)
  end
  
  context "data passed to .new" do
    before(:all) do
      @x = '<e />'
    end
    it "should have a collection field" do
      @rsolr_client.should_receive(:add).with(hash_including(:collection => @coll))
      @parser.parse(@x)
    end
    it "should have a volume_ssi field" do
      @rsolr_client.should_receive(:add).with(hash_including(:volume_ssi => @volume))
      @parser.parse(@x)
    end
    it "should have a druid field" do
      @rsolr_client.should_receive(:add).with(hash_including(:druid => @druid))
      @parser.parse(@x)
    end
  end

  context "elements - simple" do
    before(:all) do
      @x = '<e a="a1">
              <e1>v1</e1>
              <e2>v2</e2>
              <e2>v3</e2>
           </e>'
    end
    it "should have an entry for the root element " do
      @rsolr_client.should_receive(:add).with(hash_including(:e_sim))
      @parser.parse(@x)
    end
    it "should have an entry for each element" do
      @rsolr_client.should_receive(:add).with(hash_including(:e_e1_sim, :e_e2_sim))
      @parser.parse(@x)
    end
    it "should have an entry value for each occurrence of a repeated element" do
      @rsolr_client.should_receive(:add).with(hash_including(:e_e2_sim => ['v2', 'v3']))
      @parser.parse(@x)
      x = "<outer><el>first</el><el>second</el></outer>"
      exp_flds = {:el_sim => ['first', 'second'],
                  :outer_el_sim => ['first', 'second'], 
                  :outer_sim => ['first second']}
      @rsolr_client.should_receive(:add).with(hash_including(exp_flds))
      @parser.parse(x)
    end
    it "should not have an entry for an empty element with no attributes" do
      x = '<e></e>'
      @rsolr_client.should_receive(:add).with(hash_not_including(:e_sim))
      @parser.parse(x)
      x = '<e/>'
      @rsolr_client.should_receive(:add).with(hash_not_including(:e_sim))
      @parser.parse(x)
    end
    it "should not have an entry for an element with only whitespace and no attributes" do
      x = '<e>     </e>'
      @rsolr_client.should_receive(:add).with(hash_not_including(:e_sim))
      @parser.parse(x)
    end
  end # elements - simple
  
  context "element children" do
    before(:all) do
      @x = '<e>
             <e1>v1</e1>
             <e2>v2</e2>
             <e2>v3</e2>
            </e>'
    end
    it "outer element should include the values of the element children in its value, separated by space" do
      @rsolr_client.should_receive(:add).with(hash_including(:e_sim => ['v1 v2 v3']))
      @parser.parse(@x)
    end
    it "solr doc should have an entry for each subelement" do
      @rsolr_client.should_receive(:add).with(hash_including(:e_e1_sim => ['v1'], :e_e2_sim => ['v2', 'v3']))
      @parser.parse(@x)
    end
    it "solr doc should have the contents of the innermost element in all enclosing elements" do
      chars = 'anything'
      x = "<outer><middle><inner>#{chars}</inner></middle></outer>"
      exp_flds = {:inner_sim => [chars], 
                  :middle_inner_sim => [chars],
                  :outer_middle_inner_sim => [chars],
                  :middle_sim => [chars],
                  :outer_middle_sim => [chars],
                  :outer_sim => [chars] }
      @rsolr_client.should_receive(:add).with(hash_including(exp_flds))
      @parser.parse(x)
    end
    it "solr doc should have the contents of the innermost element in the right place in its enclosing elements" do
      x = "<outer>out<middle>mid<inner>in</inner>mid2</middle>out2</outer>"
      exp_flds = {:inner_sim => ['in'], 
                  :middle_inner_sim => ['in'],
                  :outer_middle_inner_sim => ['in'],
                  :middle_sim => ['mid in mid2'],
                  :outer_middle_sim => ['mid in mid2'],
                  :outer_sim => ['out mid in mid2 out2'] }
      @rsolr_client.should_receive(:add).with(hash_including(exp_flds))
      @parser.parse(x)
    end
  end # element children
  
  context "attributes" do
    it "should have entries for attributes on the root element" do
      x = '<e a="a1">
              <e1>v1</e1>
           </e>'
      @rsolr_client.should_receive(:add).with(hash_including(:e_a_sim => ['a1']))
      @parser.parse(x)
    end
    it "should have an entry for each attribute on an element" do
      x = '<e at1="a1" at2="a2">v1</e>'
      @rsolr_client.should_receive(:add).with(hash_including(:e_at1_sim => ['a1'], :e_at2_sim => ['a2']))
      @parser.parse(x)
    end
    it "should not create an entry for an empty attribute" do
      x = '<e at1="">v1</e>'
      @rsolr_client.should_receive(:add).with(hash_not_including(:e_at1_sim))
      @parser.parse(x)
    end
    it "should not create an entry for an attribute containing only whitespace" do
      x = '<e at1="   ">v1</e>'
      @rsolr_client.should_receive(:add).with(hash_not_including(:e_at1_sim))
      @parser.parse(x)
    end
    it "should have all attribute values across multiple element children" do
      x = '<e>
            <e1>v1</e1>
            <e2 at2="a2">v2</e2>
            <e2 at2="a3">v3</e2>
          </e>'
#      exp_flds = {:e2_at2_sim => ['a2', 'a3'], :e_e2_at2_sim => ['a2', 'a3']}
      exp_flds = {:e2_at2_sim => ['a2', 'a3']}
      @rsolr_client.should_receive(:add).with(hash_including(exp_flds))
      @parser.parse(x)
    end
  end # attributes
  
  context "namespaces" do
    it "should work for root element with default namespace declaration" do
      x = '<e a="a1" xmlns="foo">
              <e1>v1</e1>
           </e>'
      @rsolr_client.should_receive(:add).with(hash_including(:e_a_sim => ['a1']))
      @parser.parse(x)
    end
    it "should use namespace prefix for element name in doc_hash when there is a namespace declaration" do
      x = '<xxx:e a="a1" xmlns:xxx="foo">
              <xxx:e1>v1</xxx:e1>
           </xxx:e>'
      @rsolr_client.should_receive(:add).with(hash_including(:xxx_e_sim => ['v1'], :xxx_e1_sim => ['v1']))
      @parser.parse(x)
    end
    it "should use correct namespace prefixes when there are multiple namespace declarations" do
      x = '<xxx:e a="a1" xmlns:xxx="foo">
              <yyy:e1 xmlns:yyy="bar">v1</yyy:e1>
           </xxx:e>'
      @rsolr_client.should_receive(:add).with(hash_including(:xxx_e_sim => ['v1'], :yyy_e1_sim => ['v1']))
      @parser.parse(x)
    end
    it "a namespace is not an attribute" do
      x = '<e a="a1" xmlns:boo="foo">
              <e1>v1</e1>
           </e>'
      @rsolr_client.should_receive(:add).with(hash_not_including(:e_xmlns_boo_sim))
      @parser.parse(x)
    end
    it "should include namespace prefix for an attribute in the doc_hash" do
      x = '<e xml:lang="zurg">v1</e>'
      @rsolr_client.should_receive(:add).with(hash_including(:e_xml_lang_sim => ['zurg']))
      @parser.parse(x)
    end
  end # namespaces
  
  it "should write warning messages to the log" do
    @rsolr_client.should_receive(:add)
    @logger.should_receive(:warn).at_least(1)
    @parser.parse('<x y="<z/>"/>')
  end
  
end