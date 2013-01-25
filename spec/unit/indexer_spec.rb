require 'spec_helper'

describe Indexer do
  
  before(:all) do
    @config_yml_path = File.join(File.dirname(__FILE__), "..", "config", "ap.yml")
    @indexer = Indexer.new(@config_yml_path)
    require 'yaml'
    @yaml = YAML.load_file(@config_yml_path)
    @hdor_client = @indexer.send(:harvestdor_client)
    @fake_druid = 'oo000oo0000'
    @im_ng = Nokogiri::XML('<identityMetadata><objectLabel>Volume 36</objectLabel></identityMetadata>')
    @url = "#{@yaml['stacks']}/file/druid:#{@fake_druid}/#{@fake_druid}.xml"
  end
  
  describe "logging" do
    it "should write the log file to the directory indicated by log_dir" do
      @indexer.logger.info("indexer_spec logging test message")
      File.exists?(File.join(@yaml['log_dir'], @yaml['log_name'])).should == true
    end
  end

  it "should initialize the harvestdor_client from the config" do
    @hdor_client.should be_an_instance_of(Harvestdor::Client)
    @hdor_client.config.default_set.should == @yaml['default_set']
  end
  
  context "harvest_and_index" do
    it "should call :commit on rsolr connection once, and :add for each druid" do
      indexer = Indexer.new(@config_yml_path)
      hdor_client = indexer.send(:harvestdor_client)
      hdor_client.should_receive(:druids_via_oai).and_return(['1', '2', '3'])
      hdor_client.should_receive(:identity_metadata).with('1').and_return(@im_ng)
      hdor_client.should_receive(:identity_metadata).with('2').and_return(@im_ng)
      hdor_client.should_receive(:identity_metadata).with('3').and_return(@im_ng)
      OpenURI.should_receive(:open_uri).with(any_args).exactly(3).times.and_return('<TEI.2/>')
      indexer.solr_client.should_receive(:add).with(hash_including(:id, :volume_ssi => 'Volume 36')).exactly(3).times
      indexer.solr_client.should_receive(:commit).once
      indexer.harvest_and_index
    end
  end
  
  context "volume method" do
    it "should get the identityMetadata via the harvestdor client" do
      @hdor_client.should_receive(:identity_metadata).with(@fake_druid).and_return(@im_ng)
      @indexer.volume(@fake_druid)
    end
    it "should get the volume from the identityMetadata objectLabel" do
      @hdor_client.should_receive(:identity_metadata).with(@fake_druid).and_return(@im_ng)
      @indexer.volume(@fake_druid).should == 'Volume 36'
    end
  end
  
  context "tei" do
    it "should get the tei from the digital stacks" do
      OpenURI.should_receive(:open_uri).with(URI.parse(@url))
      @indexer.tei(@fake_druid)
    end
    it "should write a message to the log if it doesn't find the tei" do
      @indexer.logger.should_receive(:error).with('error while retrieving tei at https://stacks.stanford.edu/file/druid:oo000oo0000/oo000oo0000.xml -- 404 Not Found')
      @indexer.tei(@fake_druid)
    end
    it "should return empty TEI if it doesn't find the tei" do
      @indexer.logger.should_receive(:error)
      @indexer.tei(@fake_druid).should == "<TEI.2/>"
    end
  end
  
  context "collection" do
    it "should be populated from the yml if there is no overriding config value" do
      indexer = Indexer.new(File.join(File.dirname(__FILE__), "..", "..", "config", "ap.yml"))
      indexer.collection.should == 'archives'
    end
    it "should be the the default_set if there is no coll_fld_val in the config" do
      @indexer.collection.should == 'is_governed_by_hy787xj5878'
    end
    it "should be able to use options from the config" do
      indexer = Indexer.new(@config_yml_path, Confstruct::Configuration.new(:coll_fld_val => 'this_coll') )
      indexer.collection.should == 'this_coll'
    end
  end
  
  it "druids method should call druids_via_oai method on harvestdor_client" do
    @hdor_client.should_receive(:druids_via_oai)
    @indexer.druids
  end
    
  it "solr_client should initialize the rsolr client using the options from the config" do
    indexer = Indexer.new(nil, Confstruct::Configuration.new(:solr => { :url => 'http://localhost:2345', :a => 1 }) )
    RSolr.should_receive(:connect).with(hash_including(:a => 1, :url => 'http://localhost:2345')).and_return('foo')
    indexer.solr_client
  end
    
end