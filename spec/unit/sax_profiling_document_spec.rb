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
    @rsolr_client.should_receive(:add).with(hash_including(:el => ['first', 'second'], :outer => ['first', 'second']))
    @parser.parse(x)
  end

  it "should have the contents of the innermost element in all elements" do
    @chars = 'anything'
    @x = "<outer><middle><inner>#{@chars}</inner></middle></outer>"
    exp_flds = {:inner => [@chars], :middle => [@chars], :outer => [@chars]}
#    exp_flds = {:inner => @chars, :middle_inner => @chars, :outer_middle_inner => @chars}
    @rsolr_client.should_receive(:add).with(hash_including(exp_flds))
    @parser.parse(@x)
  end

end