require File.dirname(__FILE__) + '/../spec_helper'

describe ContentPartnersController do

  # WIP

  before(:all) do
    truncate_all_tables
    Language.create_english
    CuratorLevel.create_enumerated
    UserIdentity.create_enumerated
    @user = User.gen
    @content_partner = ContentPartner.gen(:user => @user, :full_name => 'Test content partner')
  end

#   describe 'GET new' do
#     it 'should render new only if user can create content partner'
#   end
#
#   describe 'POST create' do
#     it 'should create content partner only if user can create content partner'
#     it 'should rerender new on validation errors'
#     it 'should redirect to show on success'
#   end
#
#   describe 'GET show' do
#     it 'should render show'
#   end
#
#   describe 'GET edit' do
#     it 'should render edit only if user can update content partner'
#   end
#
#   describe 'PUT update' do
#     it 'should update content partner only if user can update content partner'
#     it 'should rerender edit on validation errors'
#     it 'should redirect to show on success'
#   end
end
