require File.dirname(__FILE__) + '/../spec_helper'

describe TaxaController do
  
  # Scenario.load :foundation
  
  before(:each) do
    Factory(:language, :label => 'English')
  end
  
  it "should report an invalid search term" do
    get :search
    assigns[:search].error_message.should == "Your search term was invalid."
  end
  
  # it "should return results" do
  #   get :search, {:q => "tiger"}
  #   pp assigns[:search]
  # end
end