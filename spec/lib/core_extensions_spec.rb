require File.dirname(__FILE__) + '/../spec_helper'

describe String do

  describe "normalize" do
    
    it "should remove undesired characters" do
      ':;,.()[]!?*_\\/"\''.normalize.should == ''
    end

    it "should remove multiple spaces, tabs" do
      "a a  a   a    a".normalize.should == "a a a a a"
      "a\ta\t a\t\ta".normalize.should == "a a a a"
    end

    it "should remove tags" do
      "<i>a</i> a <>        <><>".normalize.should == "a a "
    end

    it "should covert ascii to lower case" do
      "ABCDEFG".normalize.should == "abcdefg"
    end

    it "should do all substitutions together" do 
      "abc<\t        i>a</i>:; ,.(Laddnda\t   )[]!?*_\\dd  \t  dd/\"'".normalize.should == "abca laddnda dd dd"
    end
  
  end

end

