require File.dirname(__FILE__) + '/../spec_helper'

def it_should_render_not_found_error_page(body, logged_in_user_is_admin = false, exception_message = nil)
  page.driver.last_response.status.should == 404
  body.should have_tag('h1', 'Not found')
  body.should have_tag('form', /search/i)
  if logged_in_user_is_admin
    if exception_message.blank?
      body.should have_tag('code')
    else
      body.should have_tag('code', /#{exception_message}/)
    end
  else
    body.should_not have_tag('code')
  end
end

describe 'Errors' do
  # NOTE: Middleware exceptions e.g. MySQL Unknown Database will be caught by ActionController::Failsafe
  # and will render static /public/500.html. They will not reach ApplicationController and will not
  # render error view, thus they are not covered in this integration test.
  before(:all) do
    unless @admin = User.find_by_username('errors_integration_testing')
      truncate_all_tables
      load_foundation_cache
      @admin = User.gen(:username => 'errors_integration_testing', :admin => true)
    end
  end

  it 'should render not found error page with search form when route is unknown' do
    visit '/some/made/up/path/that/does/not/exist'
    it_should_render_not_found_error_page(body)
  end

  it 'should render not found error page with search form when action is unknown' do
    visit "/users/#{@admin.id}/some_made_up_user_action_that_does_not_exist"
    it_should_render_not_found_error_page(body)
  end

  it 'should render not found error page with search form when record is not found' do
    visit '/users/some_made_up_user_id_that_does_not_exist'
    it_should_render_not_found_error_page(body)
  end

  it 'should render not found error page with search form when CMS page is not found' do
    visit cms_page_path('some_made_up_cms_page_that_does_not_exist')
    it_should_render_not_found_error_page(body)
  end

  it 'should render error page without search form when exception suggests application has erred'
    # not sure how to force an exception for testing? in later versions of rspec anonymous controllers may help?
    # page.driver.last_response.status.should == 500

end