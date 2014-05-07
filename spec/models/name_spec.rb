# encoding: utf-8
require "spec_helper"
require 'csv'

describe Name do

  before(:each) do
    @canonical_form = CanonicalForm.gen(string: "Some name")
    @name = Name.gen(string: "Some name Auth, 1923", canonical_form: @canonical_form)
  end

  after(:each) do
    Name.delete_all
    CanonicalForm.delete_all
  end

  #TODO - removed this plugin, find replacement:
  # it { should belong_to(:canonical_form) }

  it "should require a valid #string" do
    Name.create( string: 'Tiger' ).class.should == Name
    Name.create( string: 'Tiger' ).should_not be_valid # because there's already a Tiger
  end

  it "should have italicized version of a name" do
    @name.italicized.should == "<i>Some name</i> Auth, 1923"
    @name.italicized_verified.should == 1
  end

  it "should have clean/normalized name" do
    @name.clean_name.should == "some name auth 1923"
  end
  
  it 'should identify surrogate names' do
    name = Name.create( string: 'something', ranked_canonical_form_id: 1)
    [ 'Deferribacters incertae sedis',
      'Amanita sp. 1 HKAS 38419',
      'Amanita cf. muscaria MFC-14',
      'Incertae sedis{51. 1. }',
      'Amanita cf. pantherina HKAS 26746',
      'Lactobacullus genera incertae sedis',
      'Incertae sedis{25. 15}',
      'uncultured Leucocoprinus',
      'Morchella esculenta ß ovalis Wallr.',
      'Yersinia pestis G1670',
      'Yersinia pestis Nepal516',
      'Yersinia pestis biovar Orientalis str. PEXU2',
      'Yersinia pestis FV-1',
      'Yersinia pestis KIM D27',
      'Artemisia vulgaris (type 1)',
      'Helicobacter pylori 120',
      'Helicobacter pylori HPKX_1039_AG0C1',
      'Helicobacter pylori 74B',
      'Helicobacter pylori 245',
      'Infectious bursal disease virus',
      'JC virus',
      'Doritis pulcherrima hybrid',
      'Doritis pulcherrima cultivar',
      'Heuchera sanguinea X Tiarella cordifolia',
      'Heuchera sanguinea x Tiarella cordifolia',
      'Heuchera sanguinea × Tiarella cordifolia',
      'Herpes simplexvirus',
      'Herpes simplex strain',
      'Oryza sativa Japonica Group',
      'Asteraceae environmental sample',
      'Polychaeta group',
      'Drosophila cf. polychaeta SM-2007',
      'Helicobacter pylori NCTC 11637',
      'Coccidioides posadasii RMSCC 1040',
      'Coccidioides posadasii RMSCC 2133',
      'Coccidioides posadasii CPA 0001',
      'Coccidioides posadasii str. Silveira',
      'Arctiidae_unassigned',
      'haloarchaeon TP100',
      'Amanita bacterium'].each do |str|
      name.string = str
      name.is_surrogate_or_hybrid?.should == true
    end
    
    [ 'Aus bus',
      'Aus bus Linnaeus',
      'Aus bus Linnaeus 1983',
      'Aus bus var. cus Linnaeus 1777',
      'Aus bus var. cus (Linnaeus 1785)',
      'Aus bus var. cus Linnaeus,1934',
      'Aus bus var. cus (Linnaeus,1934)',
      'Aus bus var. cus Linnaeus 1766-7',
      'Something 7-maculata'].each do |str|
      name.string = str
      name.is_surrogate_or_hybrid?.should == false
    end
  end

  it 'should identify subgenus' do
    name = Name.create( string: 'something', ranked_canonical_form_id: 1)
    [ 'Papilio (Heraclides) Hübner, 1819',
      'Papilio (Papilio) Linnaeus 1758',
      'Papilio (Papilio)'].each do |str|
      name.string = str
      name.is_subgenus?.should == true
    end
    
    [ 'Papilio',
      'Papilio Heraclides Hübner, 1819',
      'Papilio Hübner, 1819',
      'Papilio papilio',
      'Papilio (Papilio) papilio'].each do |str|
      name.string = str
      name.is_subgenus?.should == false
    end
  end

  it 'should convert "and"s for scientific but no common names' do
    common_name = Name.new
    common_name.string = 'Tom and Jerry'
    common_name.is_common_name = true
    common_name.save!
    common_name.clean_name.should == 'tom and jerry'

    sci_name = Name.new
    sci_name.string = 'Tom and Jerry'
    sci_name.save!
    sci_name.clean_name.should == 'tom & jerry'

    Name.find_by_string('Tom and Jerry').should == sci_name  # and gets converted to & before find
    Name.find_by_string('Tom and Jerry', is_common_name: true).should == common_name
  end

  describe "::prepare_clean_name" do
    it "should prepare a clean name" do
      read_test_file("clean_name.csv") do |row|
        Name.prepare_clean_name(row["original_string"]).should == row["clean_string"]
      end
    end
  end

  describe "::create_common_name" do

    it 'should do nothing if there is no name string passed to it' do
      count = Name.count
      Name.create_common_name('').should be_nil
      Name.count.should == count
    end

    it "should take a common_name_string, and return new name instance)" do
      count = Name.count
      name = Name.create_common_name("Grey \t  jay") # Note the addition of whitespace, which should be stripped
      name.string.should == 'Grey jay'
      name.canonical_form.string.should == 'Grey jay'
      name.italicized.should == '<i>Grey jay</i>'
    end

    it "should be able to modify existing common name if clean name matches" do
      name1 = Name.create_common_name("Blue \t  jay.") # Note the addition of whitespace, which should be stripped
      clean_string1 = Name.prepare_clean_name("Blue \t  jay.")
      name1.string.should == 'Blue jay.'
      name2 = Name.create_common_name("Blue \t  jay")  # Note the addition of whitespace, which should be stripped
      clean_string2 = Name.prepare_clean_name("Blue \t  jay")
      name2.string.should == 'Blue jay'
      clean_string1.should == clean_string2
      name1.id.should == name2.id
    end

    it 'should create a canonical form when one does not already exist' do
      count = CanonicalForm.count
      name = Name.create_common_name('smurf') # Note the addition of whitespace, which should be stripped
      CanonicalForm.count.should == count + 1
    end

    it 'should run prepare_clean_name on its input' do
      Name.should_receive(:prepare_clean_name).with('Care bear', is_common_name: true).at_least(1).times.and_return('care bear')
      Name.create_common_name('Care bear')
    end

    it 'should not create a CanonicalForm, and should return an existing clean name, if passed a string that, when cleaned, already exists.' do
      CanonicalForm.should_not_receive(:create)
      clean_name = Name.gen(clean_name: 'clean ferret')
      count = Name.count
      name = Name.create_common_name('clean ferret')
      name.id.should == clean_name.id
    end

  end

  describe "#taxon_concepts" do
    it "should return taxonconcepts the name is used" do

    end
  end

  # "#canonical" deprecated. I removed it. You can check 69c7287da324903b0e1da43f90b15a2e3b480999 if you want to see
  # how it looked.

  describe "#italicized_canonical" do
    it "should return the italicized canonical form" do
      @name.italicized_canonical.should == "<i>Some name</i>"
    end
  end

  describe "::find_or_create_by_string" do

    it "should create name if it does not exist" do
      name_count = Name.count
      name = Name.find_or_create_by_string("New name string")
      name.string == "New name string"
      Name.count.should == name_count + 1
    end

    # we don't want to be creating duplicates
    it "should not create name if it does exist" do
      name = Name.find_or_create_by_string(@name.string)
      name_count = Name.count
      name = Name.find_or_create_by_string(@name.string)
      name.string == @name
      Name.count.should == name_count
    end

  end

  describe  "::find_by_string" do
    it "should return a name" do
      name = Name.find_by_string(" Some           Name Auth,     1923  ")
      name.string.should == @name.string
    end
  end

end
