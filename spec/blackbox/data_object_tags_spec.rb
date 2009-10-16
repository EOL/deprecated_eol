require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

# describe 'Taxa page (HTML)' do

describe '/data_object/1/tags' do
  before(:all) do
    Scenario.load :foundation
    taxon_concept = build_taxon_concept(:images => [{}])
    @image_dato   = taxon_concept.images.last
    @user1 = create_user 'charliebrown', 'testing'
    @user2 = create_user 'charliebrown2', 'testing2'
    @image_dato.tag("key-private-old", "value-private-old", @user1)
    @image_dato.tag("key-public-old", "value-public-old", @user2)
    #during reharvesting this object will be recreated with the same guid and different id
    # it should still find all tags because it uses guid, not id for finding relevant information
    @new_image_dato = DataObject.build_reharvested_dato(@image_dato)
    @new_image_dato.tag("key-private-new", "value-private-new", @user1)
    @new_image_dato.tag("key-public-new", "value-public-new", @user2)
  end

  after :all do
    truncate_all_tables
  end

  def create_user username, password
    User.gen :username => username, :password => password
  end

  it 'should show up public and private tags for old and new version of dato after re-harvesting' do
    login_as(@user1)
    request('/').should_not include_text('login')
    res = request("/data_objects/#{@new_image_dato.id}/tags")
    res.body.should have_tag('a', :text => /key-private-old:value-private-old/, :count => 2)
    res.body.should have_tag('a', :text => /key-public-old:value-public-old/, :count => 1)
    res.body.should have_tag('a', :text => /key-private-new:value-private-new/, :count => 2)
    res.body.should have_tag('a', :text => /key-public-new:value-public-new/, :count => 1)
  end
 
  it 'should not show private tags without login' do
    request('/').should include_text('login')
    res = request("/data_objects/#{@new_image_dato.id}/tags")
    res.body.should have_tag('a', :text => /key-private-old:value-private-old/, :count => 1)
    res.body.should have_tag('a', :text => /key-public-old:value-public-old/, :count => 1)
    res.body.should have_tag('a', :text => /key-private-new:value-private-new/, :count => 1)
    res.body.should have_tag('a', :text => /key-public-new:value-public-new/, :count => 1)    
  end
end