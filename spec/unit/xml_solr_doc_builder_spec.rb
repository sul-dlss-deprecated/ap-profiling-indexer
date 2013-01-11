require 'spec_helper'

describe XmlSolrDocBuilder do
  
  before(:all) do
    @xsdb = XmlSolrDocBuilder.new
  end
  
  context "doc_hash" do
    before(:all) do
      ng_doc = Nokogiri::XML('<e a="a1">
                                <e1>v1</e1>
                                <e2>v2</e2>
                                <e2>v3</e2>
                              </e>')
      @hash = @xsdb.doc_hash(ng_doc)
    end
    it "should have an entry for each top level element" do
      @hash.should include(:e_e1_ssim)
      @hash.should include(:e_e2_ssim)
    end
    it "should have an entry value for each occurrence of a repeated element" do
      @hash.should include(:e_e2_ssim => ['v2', 'v3'])
    end
    it "should have an entry for the root element " do
      @hash.should include(:e_ssim)
    end
    it "should have entries for attributes on the root element" do
      @hash.should include(:e_a_ssim => ['a1'])
    end
  end
  
  context "doc_hash_from_element" do
    it "should create an entry for the element name symbol, value all the text descendants of the element" do
      ng_el = Nokogiri::XML('<e>v</e>').root.xpath('/e').first
      @xsdb.doc_hash_from_element(ng_el).should include(:e_ssim => ['v'])
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
      @xsdb.doc_hash_from_element(ng_el).should include(:e_at1_ssim => ['a1'])
      @xsdb.doc_hash_from_element(ng_el).should include(:e_at2_ssim => ['a2'])
    end
    it "should include namespace prefix in the Hash key symbol" do
      ng_el = Nokogiri::XML('<e xml:lang="zurg">v1</e>').root.xpath('/e').first
      @xsdb.doc_hash_from_element(ng_el).should include(:e_xml_lang_ssim => ['zurg'])
    end
    it "should not create an entry for an empty attribute" do
      ng_el = Nokogiri::XML('<e at1="">v1</e>').root.xpath('/e').first
      @xsdb.doc_hash_from_element(ng_el).should_not include(:e_at1_ssim)
    end
    it "should not create an entry for an attribute containing only whitespace" do
      ng_doc = Nokogiri::XML('<e at1="   ">v1</e>')
      ng_el = ng_doc.root.xpath('/e').first
      @xsdb.doc_hash_from_element(ng_el).should_not include(:e_at1_ssim)
    end
    context "element children" do
      before(:all) do
        ng_doc = Nokogiri::XML('<e>
                                  <e1>v1</e1>
                                  <e2>v2</e2>
                                  <e2>v3</e2>
                                </e>')
        @ng_el = ng_doc.root.xpath('/e').first
        @hash = @xsdb.doc_hash_from_element(@ng_el)
      end
      it "should include the values of the element children in its value, separated by space" do
        @hash.should include(:e_ssim => ['v1 v2 v3'])
      end
      it "should create an entry for each subelement" do
        @hash.should include(:e_e1_ssim => ['v1'])
        @hash.should include(:e_e2_ssim => ['v2', 'v3'])
      end
      it "should have all attribute values across multiple children" do
        ng_doc = Nokogiri::XML('<e>
                                  <e1>v1</e1>
                                  <e2 at2="a2">v2</e2>
                                  <e2 at2="a3">v3</e2>
                                </e>')
        ng_el = ng_doc.root.xpath('/e').first
        @xsdb.doc_hash_from_element(ng_el).should include(:e_e2_at2_ssim => ['a2', 'a3'])
      end
    end    
  end # doc_hash_from_element
  

end