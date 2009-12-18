require File.dirname(__FILE__) + '/../spec_helper'

describe Name do

  it { should belong_to(:canonical_form) }
  it { should validate_presence_of(:string) }
  it { should validate_presence_of(:italicized) }
  it { should validate_presence_of(:canonical_form) }

  it "should require a valid #string" do
    Name.gen( :string => 'Tiger' ).should be_valid
    Name.build( :string => 'Tiger' ).should_not be_valid # because there's already a Tiger
  end

  describe "#prepare_clean_name" do
    it "should prepare a clean name" do
      Name.prepare_clean_name('a.b,c;d').should == "a b c d"
      Name.prepare_clean_name("-a(b)c[d]e{f}g:i&j*k?l×").should == "- a ( b ) c [ d ] e { f } g : i & j * k ? l ×"
      Name.prepare_clean_name("  a and b et. c ").should == "a & b & c"
      Name.prepare_clean_name("ABCDEFGHIJKLMNOPQRSTUVWXYZ").should == "abcdefghijklmnopqrstuvwxyz"
      Name.prepare_clean_name("ÀÂÅÃÁÆCÇČÉÈËÍÌÏŇÑÑÓÒÔØÕÖÚÙÜRŔŘŖŠŠŞŽŒ").should == "àâåãáæcçčéèëíìïňññóòôøõöúùürŕřŗššşžœ"
      Name.prepare_clean_name("\t    a     \t\tb     c    ").should == "a b c" 
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

    it 'should run prepare_clean_name on its input' do
      Name.should_receive(:prepare_clean_name).with('Care bear').exactly(1).times.and_return('care bear')
      Name.create_common_name('Care bear')
    end

    it 'should not create a CanonicalForm, and should return an existing clean name, if passed a string that, when cleaned, already exists.' do
      CanonicalForm.should_not_receive(:create)
      clean_name = Name.gen(:clean_name => 'clean ferret')
      count = Name.count
      name = Name.create_common_name('clean ferret')
      name.id.should == clean_name.id
    end

  end

end
