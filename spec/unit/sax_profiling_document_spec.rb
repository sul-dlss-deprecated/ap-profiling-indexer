require "spec_helper"

describe SaxProfilingDocument do
  before(:all) do
    @volume = '36'
    @druid = 'aa222bb4444'
    @rsolr_client = RSolr::Client.new('http://somewhere.org')
    @atd = SaxProfilingDocument.new(@rsolr_client, @druid, @volume)
    @parser = Nokogiri::XML::SAX::Parser.new(@atd)
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
  end
  
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
  end 
  
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
    it "should include namespace prefix in the Hash key symbol" do
      x = '<e xml:lang="zurg">v1</e>'
      @rsolr_client.should_receive(:add).with(hash_including(:e_xml_lang_sim => ['zurg']))
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
      @rsolr_client.should_receive(:add).with(hash_including(:e_e2_at2_sim => ['a2', 'a3']))
      @parser.parse(x)
    end
  end # attributes
  
end