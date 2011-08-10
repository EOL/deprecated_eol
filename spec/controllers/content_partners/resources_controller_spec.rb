require File.dirname(__FILE__) + '/../../spec_helper'

describe ContentPartners::ResourcesController do

  # WIP

  before(:all) do
    truncate_all_tables
    Language.create_english
    CuratorLevel.create_defaults
    UserIdentity.create_defaults
    @user = User.gen
    @content_partner = ContentPartner.gen(:user => @user, :full_name => 'Test content partner')
  end
#TEMP
#TEMP  describe 'GET new' do
#TEMP    it 'should render new only if user can create content partner resources'
#TEMP  end
#TEMP
#TEMP  describe 'POST create' do
#TEMP    it 'should create resource only if user can create content partner resources'
#TEMP    it 'should rerender new on validation errors'
#TEMP    it 'should redirect to content partner resources index on success'
#TEMP    it 'should upload resource to server'
#TEMP  end
#TEMP
#TEMP  describe 'GET index' do
#TEMP    it 'should render index'
#TEMP  end
#TEMP
#TEMP  describe 'GET show' do
#TEMP    it 'should render error as there is no resource show page'
#TEMP  end
#TEMP
#TEMP  describe 'GET edit' do
#TEMP    it 'should render edit only if user can update this content partner resource'
#TEMP  end
#TEMP
#TEMP  describe 'PUT update' do
#TEMP    it 'should update resource only if user can update this content partner resource'
#TEMP    it 'should rerender edit on validation errors'
#TEMP    it 'should redirect to content partner resources index on success'
#TEMP  end
#TEMP
#TEMP  describe 'DELETE destroy' do
#TEMP    it 'should delete resource only if user can delete this content partner resources'
#TEMP    it 'should redirect to content partner resources index on success'
#TEMP  end
#TEMP
end
