require 'spec_helper'

describe SolrDocBuilder do

  before(:all) do
    @fake_druid = 'oo000oo0000'
    @ns_decl = "xmlns='#{Mods::MODS_NS}'"
    @mods_xml = "<mods #{@ns_decl}><note>hi</note></mods>"
    @ng_mods_xml = Nokogiri::XML(@mods_xml)
  end
  
  # NOTE:  
  # "Doubles, stubs, and message expectations are all cleaned out after each example."
  # per https://www.relishapp.com/rspec/rspec-mocks/docs/scope
  
  context "doc_hash" do
    before(:all) do
      @ng_mods_xml = Nokogiri::XML("<mods #{@ns_decl}><note>hi</note></mods>")
    end
    before(:each) do
      @hdor_client = double
      @hdor_client.stub(:mods).with(@fake_druid).and_return(@ng_mods_xml)
      @doc_hash = SolrDocBuilder.new(@fake_druid, @hdor_client, nil).doc_hash
    end
    it "id field should be set to druid" do
      @doc_hash[:id].should == @fake_druid
    end
    it "all_text_ti field should have all the text content of the document" do
      pending "to be implemented"
    end
    it "should have a field for each top level element" do
      pending "to be implemented"
    end
    it "should have a field value for each occurrence of a repeated element" do
      pending "to be implemented"
    end

    it "should call doc_hash_from_mods to populate hash fields from MODS" do
      sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil)
      sdb.should_receive(:doc_hash_from_mods)
      sdb.doc_hash
    end
  end
    
  context "doc_hash_from_mods" do
    before(:each) do
      @hdor_client = double()
    end
    
    # see https://consul.stanford.edu/display/NGDE/Required+and+Recommended+Solr+Fields+for+SearchWorks+documents

    context "<abstract> --> summary_search" do
      it "should be populated when the MODS has a top level <abstract> element" do
        m = "<mods #{@ns_decl}><abstract>blah blah</abstract></mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:summary_search].should == ['blah blah']
      end
      it "should have a value for each abstract element" do
        m = "<mods #{@ns_decl}>
              <abstract>one</abstract>
              <abstract>two</abstract>
            </mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:summary_search].should == ['one', 'two']
      end
      it "should not be present when there is no top level <abstract> element" do
        m = "<mods #{@ns_decl}><relatedItem><abstract>blah blah</abstract></relatedItem></mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil)
        sdb.doc_hash_from_mods[:summary_search].should == nil
      end
      it "should not be present if there are only empty abstract elements in the MODS" do
        m = "<mods #{@ns_decl}><abstract/><note>notit</note></mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:summary_search].should ==  nil
      end
      it "summary_display should not be populated - it is a copy field" do
        m = "<mods #{@ns_decl}><abstract>blah blah</abstract></mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:summary_display].should == nil
      end
    end # summary_search / <abstract>

    context "access_condition_display" do
      it "should be populated when the MODS has a top level <accessCondition> element" do
        m = "<mods #{@ns_decl}>
              <accessCondition type='useAndReproduction'>All rights reserved.</accessCondition>
            </mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:access_condition_display].should == ['All rights reserved.']
      end
      it "should have a value for each accessCondition element" do
        m = "<mods #{@ns_decl}>
              <accessCondition>one</accessCondition>
              <accessCondition>two</accessCondition>
            </mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:access_condition_display].should == ['one', 'two']
      end
      it "should not be present when there is no top level <accessCondition> element" do
        m = "<mods #{@ns_decl}><relatedItem><accessCondition>foo</accessCondition></relatedItem></mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil)
        sdb.doc_hash_from_mods[:access_condition_display].should == nil
      end
      it "should not be present if there are only empty accessCondition elements in the MODS" do
        m = "<mods #{@ns_decl}><accessCondition/><note>notit</note></mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:access_condition_display].should ==  nil
      end      
    end
    
    it "language: should call sw_language_facet in stanford-mods gem to populate language field" do
      @hdor_client.stub(:mods).with(@fake_druid).and_return(@ng_mods_xml)
      sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil)
      smr = sdb.smods_rec
      smr.should_receive(:sw_language_facet)
      sdb.doc_hash_from_mods
    end
    
    context "<physicalDescription><extent> --> physical" do
      it "should be populated when the MODS has mods/physicalDescription/extent element" do
        m = "<mods #{@ns_decl}><physicalDescription><extent>blah blah</extent></physicalDescription></mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:physical].should == ['blah blah']
      end
      it "should have a value for each extent element" do
        m = "<mods #{@ns_decl}>
              <physicalDescription>
                <extent>one</extent>
                <extent>two</extent>
              </physicalDescription>
              <physicalDescription><extent>three</extent></physicalDescription>
            </mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:physical].should == ['one', 'two', 'three']
      end
      it "should not be present when there is no top level <physicalDescription> element" do
        m = "<mods #{@ns_decl}><relatedItem><physicalDescription><extent>foo</extent></physicalDescription></relatedItem></mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil)
        sdb.doc_hash_from_mods[:physical].should == nil
      end
      it "should not be present if there are only empty physicalDescription or extent elements in the MODS" do
        m = "<mods #{@ns_decl}><physicalDescription/><physicalDescription><extent/></physicalDescription><note>notit</note></mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:physical].should ==  nil
      end      
    end # physical field from physicalDescription/extent

    context " /mods/relatedItem/location/url --> url_suppl " do
      it "should be populated when the MODS has mods/relatedItem/location/url " do
        m = "<mods #{@ns_decl}><relatedItem><location><url>url.org</url></location></relatedItem></mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:url_suppl].should == ['url.org']
      end
      it "should have a value for each mods/relatedItem/location/url element" do
        m = "<mods #{@ns_decl}>
              <relatedItem>
                <location><url>one</url></location>
                <location>
                  <url>two</url>
                  <url>three</url>
                </location>
              </relatedItem>
              <relatedItem><location><url>four</url></location></relatedItem>
            </mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:url_suppl].should == ['one', 'two', 'three', 'four']
      end
      it "should not be populated from /mods/location/url element" do
        m = "<mods #{@ns_decl}><location><url>hi</url></location></mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil)
        sdb.doc_hash_from_mods[:url_suppl].should == nil
      end
      it "should not be present if there are only empty relatedItem/location/url elements in the MODS" do
        m = "<mods #{@ns_decl}>
              <relatedItem><location><url/></location></relatedItem>
              <relatedItem><location/></relatedItem>
              <relatedItem/><note>notit</note></mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:url_suppl].should ==  nil
      end      
    end

    context "<tableOfContents> --> toc_search" do
      it "should be populated when the MODS has a top level <accessCondition> element" do
        m = "<mods #{@ns_decl}><tableOfContents>erg</tableOfContents></mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:toc_search].should == ['erg']
      end
      it "should have a value for each tableOfContents element" do
        m = "<mods #{@ns_decl}>
              <tableOfContents>one</tableOfContents>
              <tableOfContents>two</tableOfContents>
            </mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:toc_search].should == ['one', 'two']
      end
      it "should not be present when there is no top level <tableOfContents> element" do
        m = "<mods #{@ns_decl}><relatedItem><tableOfContents>foo</tableOfContents></relatedItem></mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil)
        sdb.doc_hash_from_mods[:toc_search].should == nil
      end
      it "should not be present if there are only empty tableOfContents elements in the MODS" do
        m = "<mods #{@ns_decl}><tableOfContents/><note>notit</note></mods>"
        @hdor_client.stub(:mods).with(@fake_druid).and_return(Nokogiri::XML(m))
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil) 
        sdb.doc_hash_from_mods[:toc_search].should ==  nil
      end      
    end
    
    context "title fields" do
      before(:all) do
        title_mods = "<mods #{@ns_decl}>
          <titleInfo><title>Jerk</title><nonSort>The</nonSort><subTitle>is whom?</subTitle></titleInfo>
          <titleInfo><title>Joke</title></titleInfo>
          <titleInfo type='alternative'><title>Alternative</title></titleInfo>
          </mods>"
        @ng_title_mods = Nokogiri::XML(title_mods)
      end
      before(:each) do
        @hdor_client.stub(:mods).with(@fake_druid).and_return(@ng_title_mods)
        @title_doc_hash = SolrDocBuilder.new(@fake_druid, @hdor_client, nil).doc_hash_from_mods
      end
      it "should call the appropriate methods in the stanford-mods gem to populate the fields" do
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil)
        smr = sdb.smods_rec
        smr.should_receive(:sw_short_title).at_least(:once)
        smr.should_receive(:sw_full_title).at_least(:once)
        smr.should_receive(:sw_addl_titles)
        smr.should_receive(:sw_sort_title)
        sdb.doc_hash_from_mods
      end
      context "search fields" do
        it "title_245a_search" do
          @title_doc_hash[:title_245a_search].should == "The Jerk"
        end
        it "title_245_search" do
          @title_doc_hash[:title_245_search].should == "The Jerk is whom?"
        end
        it "title_variant_search" do
          @title_doc_hash[:title_variant_search].should == ["Joke", "Alternative"]
        end
        it "title_related_search should not be populated from MODS" do
          @title_doc_hash[:title_related_search].should == nil
        end
      end
      context "display fields" do
        it "title_display" do
          @title_doc_hash[:title_display].should == "The Jerk is whom?"
        end
        it "title_245a_display" do
          @title_doc_hash[:title_245a_display].should == "The Jerk"
        end
        it "title_245c_display should not be populated from MODS" do
          @title_doc_hash[:title_245c_display].should == nil
        end
        it "title_full_display" do
          @title_doc_hash[:title_full_display].should == "The Jerk is whom?"
        end
        it "title_variant_display should not be populated - it is a copy field" do
          @title_doc_hash[:title_variant_display].should == nil
        end
      end
      it "title_sort" do
        @title_doc_hash[:title_sort].should == "Jerk is whom"
      end
    end # title fields  

    context "author fields" do
      before(:all) do
        name_mods = "<mods #{@ns_decl}>
                        <name type='personal'>
                          <namePart type='given'>John</namePart>
                          <namePart type='family'>Huston</namePart>
                          <role><roleTerm type='code' authority='marcrelator'>drt</roleTerm></role>
                          <displayForm>q</displayForm>
                        </name>
                        <name type='personal'><namePart>Crusty The Clown</namePart></name>
                        <name type='corporate'><namePart>Watchful Eye</namePart></name>
                        <name type='corporate'>
                          <namePart>Exciting Prints</namePart>
                          <role><roleTerm type='text'>lithographer</roleTerm></role>
                        </name>
                        <name type='conference'><namePart>conference</namePart></name>
                      </mods>"
        @ng_name_mods = Nokogiri::XML(name_mods)
      end
      before(:each) do
        @hdor_client.stub(:mods).with(@fake_druid).and_return(@ng_name_mods)
        @author_doc_hash = SolrDocBuilder.new(@fake_druid, @hdor_client, nil).doc_hash_from_mods
      end
      it "should call the appropriate methods in the stanford-mods gem to populate the fields" do
        sdb = SolrDocBuilder.new(@fake_druid, @hdor_client, nil)
        smr = sdb.smods_rec
        smr.should_receive(:sw_main_author)
        smr.should_receive(:sw_addl_authors)
        smr.should_receive(:sw_person_authors).exactly(3).times
        smr.should_receive(:sw_impersonal_authors)
        smr.should_receive(:sw_corporate_authors)
        smr.should_receive(:sw_meeting_authors)
        smr.should_receive(:sw_sort_author)
        sdb.doc_hash_from_mods
      end
      context "search fields" do
        it "author_1xx_search" do
          @author_doc_hash[:author_1xx_search].should == "Crusty The Clown"
        end
        it "author_7xx_search" do
          @author_doc_hash[:author_7xx_search].should == ["q", "Watchful Eye", "Exciting Prints", "conference"]
        end
        it "author_8xx_search should not be populated from MODS" do
          @author_doc_hash[:author_8xx_search].should == nil
        end
      end
      context "facet fields" do
        it "author_person_facet" do
          @author_doc_hash[:author_person_facet].should == ["q", "Crusty The Clown"]
        end
        it "author_other_facet" do
          @author_doc_hash[:author_other_facet].should == ["Watchful Eye", "Exciting Prints", "conference"]
        end
      end
      context "display fields" do
        it "author_person_display" do
          @author_doc_hash[:author_person_display].should == ["q", "Crusty The Clown"]
        end
        it "author_person_full_display" do
          @author_doc_hash[:author_person_full_display].should == ["q", "Crusty The Clown"]
        end
        it "author_corp_display" do
          @author_doc_hash[:author_corp_display].should == ["Watchful Eye", "Exciting Prints"]
        end
        it "author_meeting_display" do
          @author_doc_hash[:author_meeting_display].should == ["conference"]
        end
      end
      it "author_sort" do
        @author_doc_hash[:author_sort].should == "Crusty The Clown"
      end
    end # author fields

  end # doc_hash_from_mods
  
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