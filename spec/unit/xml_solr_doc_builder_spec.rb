require 'spec_helper'

describe XmlSolrDocBuilder do
  
  before(:all) do
    @xsdb = XmlSolrDocBuilder.new
  end
  
  context "doc_hash" do
    it "all_text_ti field should have all the text content of the document" do
      pending "to be implemented"
    end
    it "should have a field for each top level element" do
      pending "to be implemented"
    end
    it "should have a field value for each occurrence of a repeated element" do
      pending "to be implemented"
    end
  end
  
  context "doc_hash_from_element" do
    
    it "should create an entry for the element name symbol, value all the text descendants of the element" do
      ng_el = Nokogiri::XML('<e>v</e>').root.xpath('/e').first
      @xsdb.doc_hash_from_element(ng_el).should include(:e => 'v')
    end
    it "should include the values of the element children in its value, separated by space" do
      ng_doc = Nokogiri::XML('<e>
                                <e1>v1</e1>
                                <e2>v2</e2>
                              </e>')
      ng_el = ng_doc.root.xpath('/e').first
      @xsdb.doc_hash_from_element(ng_el).should include(:e => 'v1 v2')
    end
    it "should not create an entry for an empty element with no attributes" do
      ng_el = Nokogiri::XML('<e></e>').root.xpath('/e').first
      @xsdb.doc_hash_from_element(ng_el).should be_empty
      ng_el = Nokogiri::XML('<e/>').root.xpath('/e').first
      @xsdb.doc_hash_from_element(ng_el).should be_empty
    end
    it "should not create an entry for an element with only whitespace and no attributes" do
      ng_el = Nokogiri::XML('<e>     </e>').root.xpath('/e').first
      @xsdb.doc_hash_from_element(ng_el).should be_empty
    end
    it "should have an entry for each attribute on an element" do
      ng_el = Nokogiri::XML('<e at1="a1" at2="a2">v1</e>').root.xpath('/e').first
      @xsdb.doc_hash_from_element(ng_el).should include(:e_at1 => 'a1')
      @xsdb.doc_hash_from_element(ng_el).should include(:e_at2 => 'a2')
    end
    it "should include namespace prefix in the Hash key symbol" do
      ng_el = Nokogiri::XML('<e xml:lang="zurg">v1</e>').root.xpath('/e').first
      @xsdb.doc_hash_from_element(ng_el).should include(:e_xml_lang => 'zurg')
    end
    it "should not create an entry for an empty attribute" do
      ng_el = Nokogiri::XML('<e at1="">v1</e>').root.xpath('/e').first
      @xsdb.doc_hash_from_element(ng_el).should_not include(:e_at1)
    end
    it "should not create an entry for an attribute containing only whitespace" do
      ng_doc = Nokogiri::XML('<e at1="   ">v1</e>')
      ng_el = ng_doc.root.xpath('/e').first
      @xsdb.doc_hash_from_element(ng_el).should_not include(:e_at1)
    end
    it "should create an entry for each subelement" do
      pending "to be implemented"
    end
    
  end
  

end