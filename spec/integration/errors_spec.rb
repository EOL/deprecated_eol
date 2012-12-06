require File.dirname(__FILE__) + '/../spec_helper'

describe 'Errors' do
  # NOTE: Middleware exceptions e.g. MySQL Unknown Database will be caught by ActionController::Failsafe
  # and will render static /public/500.html. They will not reach ApplicationController and will not
  # render error view, thus they are not covered in this integration test.
  before(:all) do
    unless @admin = User.find_by_username('errors_integration_testing')
      load_foundation_cache
      @admin = User.gen(:username => 'errors_integration_testing', :admin => true)
    end
  end

  it 'should render not found error page with search form when route is unknown' do
    lambda { visit '/some/made/up/path/that/does/not/exist' }.should raise_error(ActionController::RoutingError)
  end

  it 'should render not found error page with search form when action is unknown' do
    lambda { visit "/users/#{@admin.id}/some_made_up_user_action_that_does_not_exist" }.should
      raise_error(ActionController::RoutingError)
  end

  it 'should render not found error page with search form when record is not found' do
    lambda { visit '/users/some_made_up_user_id_that_does_not_exist' }.should
      raise_error(ActionController::RoutingError)
  end

  it 'should render not found error page with search form when CMS page is not found' do
    lambda { visit cms_page_path('some_made_up_cms_page_that_does_not_exist') }.should
      raise_error(ActionController::RoutingError)
  end

end
