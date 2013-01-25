# encoding: utf-8
require "spec_helper"

# tests specific to Archives Parlementaires TEI profiling
describe ApTeiProfilingDocument do
  before(:all) do
    @coll = 'archives'
    @volume = '36'
    @druid = 'aa222bb4444'
    @rsolr_client = RSolr::Client.new('http://somewhere.org')
    @logger = Logger.new(STDOUT)
    @atd = ApTeiProfilingDocument.new(@rsolr_client, @druid, @volume, @coll, @logger)
    @parser = Nokogiri::XML::SAX::Parser.new(@atd)
  end

# FIXME:  also want to run SaxProfilingDocument spec  
  
  context "initial xml instructuions" do
    it "should ignore all the initial xml instructions" do
      x = '<?xml version="1.0" encoding="UTF-8"?>
      <?xml-stylesheet type="text/css" href="layout.css"?>
      <!DOCTYPE TEI.2 PUBLIC "-//TEI P4//ELEMENTS TEI Lite XML ver. 1//EN" "http://www.tei-c.org/Lite/DTD/teixlite.dtd">
      <TEI.2>
        <text>
          <body>
            <div1 type="volume" n="48">
            </div1>
          </body>
        </text>
      </TEI.2>'
      exp_hash = {:id => @druid, :volume_ssi => @volume, :collection => @coll, :div1_type_sim => ['volume'], :div1_n_sim => ['48']}
      @rsolr_client.should_receive(:add).with(exp_hash)
      @parser.parse(x)
    end
  end
  
  context "ignored elements" do
    before(:all) do
      @x = '<TEI.2><text>
            <front>
              <div type="frontpiece">
                <pb n="" id="ns351vc7243_00_0001"/> 
                <p>ARCHIVES PARLEMENTAIRES </p>
              </div>
            </front>
            <body>
              <div1 type="volume" n="48">
                <pb n="" id="ns351vc7243_00_0004"/>
                <head>ARCHIVES PARLEMENTAIRES </head>
                <div2 type="session">
                  <pb n="3" id="ns351vc7243_00_0006"/>
                  <p>ASSEMBLÉE NATIONALE LÉGISLATIVE. </p>
                </div2>
              </div1>
            </body>
          </text></TEI.2>'
    end
    it "should ignore the <TEI.2 element>" do
      @rsolr_client.should_receive(:add).with(hash_not_including(:"TEI.2_sim", :TEI_2_sim))
      @parser.parse(@x)
    end
    it "should ignore the <text> element" do
      @rsolr_client.should_receive(:add).with(hash_not_including(:text_sim, :"TEI.2_text_sim"))
      @parser.parse(@x)
    end
    it "should ignore the <pb> element and its attributes" do
      @rsolr_client.should_receive(:add).with(hash_not_including(:pb_n_sim, :pb_id_sim, :pb_sim))
      @parser.parse(@x)
    end
    context "should ignore the immediate content of the <item> element" do
      before(:all) do
        @x = '<TEI.2><text>
              <back>
                <div1 type="volume" n="48">
                  <pb n="" id="ns351vc7243_00_0719"/>
                  <head>ARCHIVES PARLEMENTAIRES </head>
                  <div2 type="contents">
                    <head>TABLE CHRONOLOGIQUE DU TOME XLVIII </head>
                    <list>
                      <head>
                        <date value="1792-08-01">SAMEDI 1 AOUT 1792</date>. Suite de la</head>
                      <item>Pages. </item>
                      <item>non non</item>
                      <item>me oui</item>
                    </list>
                   </div2>
                 </div1>
               </back></text></TEI.2>'
        @orig_vals = ['Pages.', 'non non', 'me oui']
      end
      it "should ignore the immediate text of an <item> element" do
        @rsolr_client.should_receive(:add).with(hash_not_including(:item_sim))
        @parser.parse(@x)
      end
      it "parents of <item> should also ignore <item> element" do
        @rsolr_client.should_receive(:add).with(hash_not_including(:list_item_sim, :div2_list_head_item_sim))
        @parser.parse(@x)
      end      
    end
  end
  
  context "<p> element" do
    before(:all) do
      @x1 = '<TEI.2><text>
            <body>
              <div1 type="volume" n="48">
                <pb n="" id="ns351vc7243_00_0004"/>
                <head>ARCHIVES PARLEMENTAIRES </head>
                <head>RÈGNE DE LOUIS XVI </head>
                <div2 type="session">
                  <p>keep1</p>
                  <p>  <date value="1792-08-11">my date</date>keep2 </p>
                  <p>keep3</p>
                  <sp>
                    <speaker>M. le Président</speaker>
                    <p> remercie Mlle Lacombe et lui accorde les honneurs de la séance. </p>
                    <p> oui oui </p>
                  </sp>
                </div2>
              </div1>
            </body></text></TEI.2>'
      @x2 = '<TEI.2><text>
              <body>
                <div1 type="volume" n="4">
                  <pb n="1" id="xg914wh0253_00_0005"/> 
                  <head>ARCHIVES PARLEMENTAIRES </head>
                  <div2 type="other">   
                    <head>BAILLIAGE DE MIRECOURT. </head>
                    <div3 type="other">
                      <head>CAHIER </head>
                      <head>Des plaintes et doléances du clergé du bailliage de Mirecourt (1). </head>
                      <p>Du <date value="1789-03-27">27 mars 1789</date>. </p>
                      <p>replace1</p>
                      <note place="foot">(1) Nous publions ce cahier</note>
                      <p>replace2</p>
                    </div3>
                  </div2>
                </div1>
              </body></text></TEI.2>'
    end
#    it "should keep the text of <p> if it's not inside an <sp> element (in <body>)" do
#      p_text_retained = ['keep1', 'keep2', 'keep3']
#      @rsolr_client.should_receive(:add).with(hash_including(:p_sim => p_text_retained))
#      @parser.parse(@x1)
#      p_text_retained = ['keep1', 'my date keep2']
#      @rsolr_client.should_receive(:add).with(hash_including(:p_sim => p_text_retained))
#      @parser.parse(@x2)
#    end
#    it "should replace the text of <p> with 'blah' if it is inside an <sp> element (in <body>)" do
#      @rsolr_client.should_receive(:add).with(hash_not_including(:p_sim => ['oui oui']))
#      @parser.parse(@x1)
#      @rsolr_client.should_receive(:add).with(hash_including(:p_sim => ['blah', 'blah']))
#      @parser.parse(@x1)
#      @rsolr_client.should_receive(:add).with(hash_not_including(:p_sim => ['replace1', 'replace2']))
#      @parser.parse(@x2)
#      @rsolr_client.should_receive(:add).with(hash_including(:p_sim => ['blah', 'blah']))
#      @parser.parse(@x2)
#    end
#    it "parents of p elements shouldn't have the text either" do
#      @rsolr_client.should_receive(:add).with(hash_including(:div2_sim => ['oui oui']))
#      @parser.parse(@x1)
#    end
#    it "should keep the text in <p> in the <front> section" do
#      x = '<TEI.2><text>
#            <front>
#             <div type="frontpiece">
#              <pb n="i" id="pz516hw4711_00_0001"/>
#              <p>ARCHIVES PARLEMENTAIRES </p>
#             </div>
#             <div type="hafltitle">
#              <pb n="iii" id="pz516hw4711_00_0003"/>
#              <p>ARCHIVES RARLEMENTAIRES DE 1787 A 1860 </p>
#              <p>something</p>
#             </div>
#            </front>
#          </text></TEI.2>'
#      p_text_retained = ['ARCHIVES PARLEMENTAIRES', 'ARCHIVES RARLEMENTAIRES DE 1787 A 1860', 'something']
#      @rsolr_client.should_receive(:add).with(hash_including(:p_sim => p_text_retained))
#      @parser.parse(x)
#    end
  end
    
  context "back//div2[@type='contents']" do
    before(:all) do
      @x = '<TEI.2><text>
            <back>
              <div1 type="volume" n="48">
                <pb n="" id="ns351vc7243_00_0719"/>
                <head>ARCHIVES PARLEMENTAIRES </head>
                <div2 type="contents">
                  <head>TABLE CHRONOLOGIQUE DU TOME XLVIII </head>
                  <list>
                    <head>
                      <date value="1792-08-01">SAMEDI 1 AOUT 1792</date>. Suite de la</head>
                    <item>Pages. </item>
                    <item>non non</item>
                    <item>me oui</item>
                  </list>
                 </div2>
               </div1>
             </back></text></TEI.2>'
      @orig_vals = ['Pages.', 'non non', 'me oui']
    end
    it "should ignore the immediate text of an <item> element" do
      @rsolr_client.should_receive(:add).with(hash_not_including(:item_sim))
      @parser.parse(@x)
    end
    it "parents of <item> should also ignore <item> element" do
      @rsolr_client.should_receive(:add).with(hash_not_including(:list_item_sim, :div2_list_head_item_sim))
      @parser.parse(@x)
    end
    it "should index the head element" do
      exp_vals = ["ARCHIVES PARLEMENTAIRES", "TABLE CHRONOLOGIQUE DU TOME XLVIII", 'SAMEDI 1 AOUT 1792 . Suite de la']
      @rsolr_client.should_receive(:add).with(hash_including(:head_sim => exp_vals))
      @parser.parse(@x)
    end
    it "should index the date element" do
      exp_flds = {:date_sim => ['SAMEDI 1 AOUT 1792'], :date_value_sim => ['1792-08-01'], :head_date_sim => ['SAMEDI 1 AOUT 1792']}
      @rsolr_client.should_receive(:add).with(hash_including())
      @parser.parse(@x)
    end
  end
  
  context "back//div2[@type='alpha']" do
    before(:all) do
      @x = '<TEI.2><text>
              <back>
                <div1 type="volume" n="48">
                  <pb n="" id="ns351vc7243_00_0752"/>
                  <head>ARCHIVES PARLEMENTAIRES </head>
                  <div2 type="alpha">
                    <head>B</head>
                    <p><term>Bachmann,</term> lieutenant-colonel du régiment de Salis-Sa-</p>
                  </div2>
                </div1>
              </back></text></TEI.2>'
    end
    it "should retain the <term> data inside the <p>" do
      @rsolr_client.should_receive(:add).with(hash_including(:term_sim => ['Bachmann,']))
      @parser.parse(@x)
    end
#    it "should replace the other data inside the <p> with blah" do
#      @rsolr_client.should_receive(:add).with(hash_including(:p_sim => ['Bachmann, blah']))
#      @parser.parse(@x)
#    end
  end
    
end