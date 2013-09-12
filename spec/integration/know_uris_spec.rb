require File.dirname(__FILE__) + '/../spec_helper'

describe "Known URIs" do

  before(:all) do
    Vetted.create_defaults
    Visibility.create_defaults
    UriType.create_defaults
    @user = FactoryGirl.create(:admin)
    SpecialCollection.create_defaults
    login_as @user
    @measurement = FactoryGirl.create(:known_uri_measurement)
    @name = FactoryGirl.create(:translated_known_uri, known_uri: @measurement).name
    @value_1 = FactoryGirl.create(:known_uri_value)
    @value_2 = FactoryGirl.create(:known_uri_value)
  end

  it 'should be able to add allowed values to measurements' do
    visit edit_known_uri_path(@measurement)
    debugger
    check @name
    click_button "Save"
    # We're back at the index, but rather than figure out which edit button to hit:
    visit edit_known_uri_path(@measurement)
    body.should have_selector("#allowed_values[checked=checked][value=#{@value_1.id}]")
  end

end
