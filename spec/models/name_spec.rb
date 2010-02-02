require File.dirname(__FILE__) + '/../spec_helper'

describe Name do

  it { should belong_to(:canonical_form) }
  #it { should validate_presence_of(:string) }
  #it { should validate_presence_of(:italicized) }
  #it { should validate_presence_of(:canonical_form) }

  it "should require a valid #string" do
    Name.create( :string => 'Tiger' ).class.should == Name
    Name.create( :string => 'Tiger' ).should_not be_valid # because there's already a Tiger
  end
  
  describe "#callbacks" do
    name = Name.create(:string => "Some test string")
    name.class.should == Name
    name.canonical_form.string.should == "Some test string"
    name.canonical_verified.should == 0
    name.italicized.should == "<i>Some test string</i>"
    name.italicized_verified.should == 0
    name.clean_name.should == "some test string"
    
    # we don't want to be creating duplicates
    name2 = Name.find_or_create_by_string(name.string)
    name2.should == name
    name2 = Name.find_or_create_by_string(" #{name.string} ")
    name2.should == name
    
    Name.delete_all
    name3 = Name.new
    name3.string = name.string
    name3.canonical_form = CanonicalForm.create(:string => "something else")
    name3.save!
    name3.canonical_form.string.should == "something else"
  end

  describe "#prepare_clean_name" do

    it "should prepare a clean name" do
      read_test_file("clean_name.csv") do |row|
        Name.prepare_clean_name(row["original_string"]).should == row["clean_string"]
      end
    end
  end
  
  describe "#create_common_name" do

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

end
