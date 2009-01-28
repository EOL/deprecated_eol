require File.dirname(__FILE__) + '/../spec_helper'

describe 'Home page' do

  scenario :foundation, :before => :all

  it 'should say EOL somewhere' do
    request('/').body.should include('EOL')
  end

  it "should have Edward O. Wilson's quote" do
    request('/').body.should include('Imagine an electronic page for each species of organism on Earth')
  end

end
