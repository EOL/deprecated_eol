require File.dirname(__FILE__) + '/../../spec_helper'

describe ContentPartners::ContentPartnerContactsController do

  # WIP

  before(:all) do
    truncate_all_tables
    Language.create_english
    CuratorLevel.create_enumerated
    UserIdentity.create_defaults
    @user = User.gen
    @content_partner = ContentPartner.gen(:user => @user, :full_name => 'Test content partner')
  end

#   describe 'GET new' do
#     it 'should render new only if user can create content partner contacts'
#   end
#
#   describe 'POST create' do
#     it 'should create contact only if user can create content partner contacts'
#     it 'should rerender new on validation errors'
#     it 'should redirect to content partner show on success'
#   end
#
#   describe 'GET index' do
#     it 'should render error as there is no contact index page'
#   end
#
#   describe 'GET show' do
#     it 'should render error as there is no contact show page'
#   end
#
#
#   describe 'GET edit' do
#     it 'should render edit only if user can update this content partner contact'
#   end
#
#   describe 'PUT update' do
#     it 'should update contact only if user can update this content partner contact'
#     it 'should rerender edit on validation errors'
#     it 'should redirect to content partner show on success'
#   end
#
#   describe 'DELETE destroy' do
#     it 'should delete contact only if user can delete this content partner contact'
#     it 'should redirect to content partner show on success'
#   end

end
