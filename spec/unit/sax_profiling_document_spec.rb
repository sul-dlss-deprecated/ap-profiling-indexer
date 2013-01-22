require "spec_helper"

describe SaxProfilingDocument do
  before(:all) do
    @volume = '36'
    @druid = 'aa222bb4444'
    @rsolr_client = RSolr::Client.new('http://somewhere.org')
    @atd = SaxProfilingDocument.new(@rsolr_client, @druid, @volume)
    @parser = Nokogiri::XML::SAX::Parser.new(@atd)
  end

  it "should deal with multiples of elements" do
    x = "<outer><el>first</el><el>second</el></outer>"
    exp_flds = {:el => ['first', 'second'],
                :outer_el => ['first', 'second'], 
                :outer => ['first second']}
    @rsolr_client.should_receive(:add).with(hash_including(exp_flds))
    @parser.parse(x)
  end

  it "should have the contents of the innermost element in all enclosing elements" do
    chars = 'anything'
    x = "<outer><middle><inner>#{chars}</inner></middle></outer>"
    exp_flds = {:inner => [chars], 
                :middle_inner => [chars],
                :outer_middle_inner => [chars],
                :middle => [chars],
                :outer_middle => [chars],
                :outer => [chars] }
    @rsolr_client.should_receive(:add).with(hash_including(exp_flds))
    @parser.parse(x)
  end

  it "should have the contents of the innermost element in all elements" do
    x = "<outer>out<middle>mid<inner>in</inner>mid2</middle>out2</outer>"
    exp_flds = {:inner => ['in'], 
                :middle_inner => ['in'],
                :outer_middle_inner => ['in'],
                :middle => ['mid in mid2'],
                :outer_middle => ['mid in mid2'],
                :outer => ['out mid in mid2 out2'] }
    @rsolr_client.should_receive(:add).with(hash_including(exp_flds))
    @parser.parse(x)
  end
end