# encoding: utf-8
require File.dirname(__FILE__) + '/../../spec_helper'

describe 'API:Docs' do
  before(:all) do
    load_foundation_cache
    # create some entry in the default hierarchy with an identifier - needed to render some API docs
    build_hierarchy_entry(0, TaxonConcept.gen, Name.gen, :identifier => 12345, :hierarchy => Hierarchy.default)
  end

  it 'there should be at least 9 API methods' do
    # [ :ping, :pages, :search, :collections, :data_objects, :hierarchy_entries, :hierarchies, :provider_hierarchies, :search_by_provider ]
    EOL::Api::METHODS.length.should >= 9
  end

  it 'should render an index page' do
    visit '/api/docs/'
    EOL::Api::METHODS.each do |method_name|
      latest_version_method = EOL::Api.default_version_of(method_name)
      body.should have_selector("tr td a[text()='#{method_name}']")
      # removing everything after the first <br> since have_selector doesn't handle nested tags
      body.should have_selector("td", :text => latest_version_method.brief_description.gsub(/<br.*/, ''))
    end
  end

  it 'should render a page for each method, showing the parameters' do
    EOL::Api::METHODS.each do |method_name|
      latest_version_method = EOL::Api.default_version_of(method_name)
      visit '/api/docs/' + method_name.to_s
      body.should include method_name.to_s
      body.gsub(/\n/, '').should include latest_version_method.description
      latest_version_method.parameters.each do |p|
        body.should have_selector("tr td[text()=#{p.name}]")
        # removing everything after the first <a> since have_selector doesn't handle nested tags
        body.should have_selector("td", :text => p.notes.gsub(/<a.*/, '')) unless p.notes.blank?
      end
    end
  end

  it 'should have a form with each parameter as a field' do
    EOL::Api::METHODS.each do |method_name|
      latest_version_method = EOL::Api.default_version_of(method_name)
      visit '/api/docs/' + method_name.to_s
      body.should have_selector("form#api_test_form[action$='/api/#{method_name}/#{latest_version_method::VERSION}']")
      latest_version_method.parameters.each do |p|
        if p.boolean? || p.array?
          body.should have_selector("form#api_test_form select[name='#{p.name}']")
        else
          body.should have_selector("form#api_test_form input[name='#{p.name}']")
        end
      end
    end
  end
end
