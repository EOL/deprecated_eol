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

  describe 'GET new' do
    it 'should render new only if user can create content partner resources'
  end

  describe 'POST create' do
    it 'should create resource only if user can create content partner resources'
    it 'should rerender new on validation errors'
    it 'should redirect to content partner resources index on success'
    it 'should upload resource to server'
  end

  describe 'GET index' do
    it 'should render index'
  end

  describe 'GET show' do
    it 'should render error as there is no resource show page'
  end

  describe 'GET edit' do
    it 'should render edit only if user can update this content partner resource'
  end

  describe 'PUT update' do
    it 'should update resource only if user can update this content partner resource'
    it 'should rerender edit on validation errors'
    it 'should redirect to content partner resources index on success'
  end

  describe 'DELETE destroy' do
    it 'should delete resource only if user can delete this content partner resources'
    it 'should redirect to content partner resources index on success'
  end

end