require File.dirname(__FILE__) + '/../spec_helper'

describe Name do

  before(:all) do
    @canonical_form = CanonicalForm.gen(:string => "Some name")
    @name = Name.gen(:string => "Some name Auth, 1923", :canonical_form => @canonical_form)
  end

  after(:all) do
    Name.delete_all
    CanonicalForm.delete_all
  end

  it { should belong_to(:canonical_form) }

  it "should require a valid #string" do
    Name.create( :string => 'Tiger' ).class.should == Name
    Name.create( :string => 'Tiger' ).should_not be_valid # because there's already a Tiger
  end

  it "should have italicized version of a name" do
    @name.italicized.should == "<i>Some name</i> Auth, 1923"
    @name.italicized_verified.should == 1
  end

  it "should have clean/normalized name" do
    @name.clean_name.should == "some name auth 1923"
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
      name = Name.create_common_name("Blue \t  jay") # Note the addition of whitespace, which should be stripped
      Name.count.should == count + 1
      name.string.should == 'Blue jay'
      name.canonical_form.string.should == 'Blue jay'
      name.italicized.should == '<i>Blue jay</i>'
    end

    it "should be able to modify existing common name if clean name matches" do
      count = Name.delete_all
      name1 = Name.create_common_name("Blue \t  jay.") # Note the addition of whitespace, which should be stripped
      clean_string1 = Name.prepare_clean_name("Blue \t  jay.")
      name1.string.should == 'Blue jay.'
      name2 = Name.create_common_name("Blue \t  jay")  # Note the addition of whitespace, which should be stripped
      clean_string2 = Name.prepare_clean_name("Blue \t  jay")
      name2.string.should == 'Blue jay'
      clean_string1.should == clean_string2
      Name.count.should == 1  # Note we added 2 names(i.e. name1 & name2) but still count should increase by 1
    end

    it 'should create a canonical form when one does not already exist' do
      Name.delete_all(:clean_name => 'smurf')
      CanonicalForm.delete_all(:string => 'smurf')
      count = CanonicalForm.count
      name = Name.create_common_name('smurf') # Note the addition of whitespace, which should be stripped
      CanonicalForm.count.should == count + 1
    end

    #it 'should run prepare_clean_name on its input' do
    #  Name.should_receive(:prepare_clean_name).with('Care bear').exactly(1).times.and_return('care bear')
    #  Name.create_common_name('Care bear')
    #end

    it 'should not create a CanonicalForm, and should return an existing clean name, if passed a string that, when cleaned, already exists.' do
      CanonicalForm.should_not_receive(:create)
      clean_name = Name.gen(:clean_name => 'clean ferret')
      count = Name.count
      name = Name.create_common_name('clean ferret')
      name.id.should == clean_name.id
    end

  end

  describe "#taxon_concepts" do
    it "should return taxonconcepts the name is used" do

    end
  end

  describe "#canonical" do

    it "should return the canonical form if assigned" do
      @name.canonical.should == "Some name"
      @name.canonical_verified.should == 1
    end

    it "should not return the canonical form if not assigned" do
      name = Name.gen(:string => "Test string")
      name.canonical_form = nil
      name.canonical_verified = 0
      name.canonical.should == 'not assigned'
    end

  end

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
      (Name.count - name_count).should == 1
    end

    # we don't want to be creating duplicates
    it "should not create name if it does exist" do
      name_count = Name.count
      name = Name.find_or_create_by_string(@name.string)
      name.string == @name
      (Name.count - name_count).should == 0
    end

  end

  describe  "::find_by_string" do
    it "should return a name" do
      name = Name.find_by_string(" Some           Name Auth,     1923  ")
      name.should == @name
    end
  end

end
