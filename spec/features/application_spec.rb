require "spec_helper"

# TODO - these are fragile tests. We should mock the responses: we shouldn't have to be connected to get these, and
# we shouldn't have to change our tests if, say, CNN changes its title.
#
# Also, why is this file named features/application_spec ? It's testing #fetch_external_page_title in application_controller, so
# it should be a "controller spec," but also that method really doesn't belong in the controller; it should be in a model, and
# this should be a model spec. This is NOT testing the behavior of the site. ...This spec is just ... misplaced. 
#
# Looking at the method, there's also a ton there that isn't being spec'ed.  :\
describe 'Application' do

  it 'should be able to get external page titles' do
    stub_request(:get, "http://eol.org/").
      with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(status: 200, body: "<title>Encyclopedia of Life</title>", headers: {})
    response = get_as_json(fetch_external_page_title_path(lang: 'en', url: 'http://eol.org'))
    response.class.should == Hash
    response['message'].should =~ /Encyclopedia of Life/
    response['exception'].should == false
  end

  it 'should not require an http prefix' do
    stub_request(:get, "http://eol.org/"). # NOTE - we DO add the http in the actual request. The assumption is that the code adds it.
      with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(status: 200, body: "<title>Encyclopedia of Life</title>", headers: {})
    response = get_as_json(fetch_external_page_title_path(lang: 'en', url: 'eol.org'))
    response.class.should == Hash
    response['message'].should =~ /Encyclopedia of Life/
    response['exception'].should == false
  end

  it 'should be able to follow redirects' do
    stub_request(:get, "http://foo.org/").
      with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(status: 302, headers: {'Location' => 'http://bar.org/'})
    stub_request(:get, "http://bar.org/").
      with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(status: 200, body: "<title>Redirected</title>", headers: {})
    response = get_as_json(fetch_external_page_title_path(lang: 'en', url: 'http://foo.org/'))
    response.class.should == Hash
    response['message'].should == "Redirected"
    response['exception'].should == false
  end

  it 'should be able to get titles from compressed pages' do
    body = ActiveSupport::Gzip.compress('<title>Zipped</title>')
    stub_request(:get, "http://zip.org/").
      with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(status: 200, body: body, headers: {'Content-Encoding' => 'gzip'})
    response = get_as_json(fetch_external_page_title_path(lang: 'en', url: 'http://zip.org/'))
    response.class.should == Hash
    response['message'].should == "Zipped"
    response['exception'].should == false
  end

  it 'should fail on inaccessible URLs' do
    response = get_as_json(fetch_external_page_title_path(lang: 'en', url: 'asgfqrwgqwfwf'))
    response.class.should == Hash
    response['message'].should == "This URL is not accessible"
    response['exception'].should == true
  end

  it 'should give a message if a title is not identified' do
    stub_request(:get, "http://bad.request/something").
      with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(status: 200, body: "<nothing here></nothing>", headers: {})
    response = get_as_json(fetch_external_page_title_path(lang: 'en', url: 'http://bad.request/something'))
    response.class.should == Hash
    response['message'].should == "Unable to determine the title of this web page"
    response['exception'].should == true
  end

  it "gives a message if the doi-link and accepts it" do 
    url= "http://dx.doi.org/10.1038/nature13812"
    redirected_url= 'http://www.nature.com/doifinder/10.1038/nature13812'
    stub_request(:get, url).to_return(status: 302, headers: { location: redirected_url } )
    stub_request(:get, redirected_url).to_return(status: 301)
    response = get_as_json(fetch_external_page_title_path(lang: 'en', url: url))
    expect(response.class).to eq(Hash)
    expect(response['message']).to eq(I18n.t(:redirect_url_ok_title_unavailable))
    expect(response['exception']).to be_true
  end

end
