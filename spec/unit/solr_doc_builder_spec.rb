require 'spec_helper'

describe SolrDocBuilder do

  before(:all) do
    @fake_druid = 'oo000oo0000'
    @ns_decl = "xmlns='#{Mods::MODS_NS}'"
    @mods_xml = "<mods #{@ns_decl}><note>hi</note><name><namePart>Shindy</namePart></name></mods>"
    @ng_mods_xml = Nokogiri::XML(@mods_xml)
  end
  
  # NOTE:  
  # "Doubles, stubs, and message expectations are all cleaned out after each example."
  # per https://www.relishapp.com/rspec/rspec-mocks/docs/scope
  
  context "doc_hash" do
    before(:each) do
      @hdor_client = double
      @hdor_client.stub(:mods).with(@fake_druid).and_return(@ng_mods_xml)
      @doc_hash = SolrDocBuilder.new(@fake_druid, @hdor_client, nil).doc_hash
    end
    it "id field should be set to druid" do
      @doc_hash[:id].should == @fake_druid
    end
    it "all_text_ti field should have all the text content of the document" do
      @doc_hash.should include(:all_text_ti => 'hi Shindy')
    end
    it "should not have a field for the mods element" do
      @doc_hash.should_not include(:mods_sim)
    end
    it "should not have mods_ as prefix in field names" do
      @doc_hash.keys.each { |k| k.to_s.should_not =~ /$mods_.*/}
    end
    it "should have a field for each top level element" do
      @doc_hash.should include(:note_sim => ['hi'])
      @doc_hash.should include(:name_sim => ['Shindy'])
      @doc_hash.should include(:name_namePart_sim => ['Shindy'])
    end
    it "should call XmlSolrDocBuilder to populate hash fields from MODS" do
      XmlSolrDocBuilder.any_instance.should_receive(:doc_hash).and_return([])
      SolrDocBuilder.new(@fake_druid, @hdor_client, nil).doc_hash
    end
  end
      
  context "using Harvestdor::Client" do
    before(:all) do
      config_yml_path = File.join(File.dirname(__FILE__), "..", "config", "bnf.yml")
      @indexer = Indexer.new(config_yml_path)
      @real_hdor_client = @indexer.send(:harvestdor_client)
    end
    context "smods_rec method (called in initialize method)" do
      it "should return Stanford::Mods::Record object" do
        @real_hdor_client.stub(:mods).with(@fake_druid).and_return(@ng_mods_xml)
        sdb = SolrDocBuilder.new(@fake_druid, @real_hdor_client, nil)
        sdb.smods_rec.should be_an_instance_of(Stanford::Mods::Record)
      end
      it "should raise exception if MODS xml for the druid is empty" do
        @real_hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML("<mods #{@ns_decl}/>"))
        expect { SolrDocBuilder.new(@fake_druid, @real_hdor_client, nil) }.to raise_error(RuntimeError, Regexp.new("^Empty MODS metadata for #{@fake_druid}: <"))
      end
      it "should raise exception if there is no MODS xml for the druid" do
        expect { SolrDocBuilder.new(@fake_druid, @real_hdor_client, nil) }.to raise_error(Harvestdor::Errors::MissingMods)
      end
    end
  end # context using Harvestdor::Client

end