require File.dirname(__FILE__) + '/../../spec_helper'

describe Admins::TranslatedContentPagesController do
  before(:all) do
    load_foundation_cache
    @admin = User.gen
    @admin.grant_admin
    @cms_user = User.gen
    @cms_user.grant_permission(:edit_cms)
    @normal_user = User.gen
  end

  let(:content_page) { ContentPage.gen }

  before(:each) do
    session[:user_id] = nil
  end

  it 'should redirect non-logged-in users to a login page' do
    session[:user_id] = nil
    get :new
    expect(response).to redirect_to(login_url)
  end

  it 'should raise SecurityViolation for average_users' do
    session[:user_id] = @normal_user.id
    expect { get :new }.to raise_error(EOL::Exceptions::SecurityViolation)
  end

  it 'should not raise an error for admins or CMS viewers' do
    session[:user_id] = @admin.id
    expect { get :new, content_page_id: content_page.id }.not_to raise_error
    session[:user_id] = @cms_user.id
    expect { get :new, content_page_id: content_page.id }.not_to raise_error
  end

end
