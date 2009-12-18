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

  it "should clean a scientific name" do
    Name.clean_name('a.b,c;d').should == "a b c d"
    Name.clean_name("-a(b)c[d]e{f}g:i&j*k?l×").should == "- a ( b ) c [ d ] e { f } g : i & j * k ? l ×"
    Name.clean_name("  a and b et. c ").should == "a & b & c"
    Name.clean_name("ABCDEFGHIJKLMNOPQRSTUVWXYZ").should == "abcdefghijklmnopqrstuvwxyz"
    Name.clean_name("ÀÂÅÃÁÆCÇČÉÈËÍÌÏŇÑÑÓÒÔØÕÖÚÙÜRŔŘŖŠŠŞŽŒ").should == "àâåãáæcçčéèëíìïňññóòôøõöúùürŕřŗššşžœ"
    Name.clean_name("\t    a     \t\tb     c    ").should == "a b c" 
  end

end
