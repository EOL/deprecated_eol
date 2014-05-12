require 'spec_helper'

describe EOLWebService do
  before(:all) do 
    @url = 'http://usr:pass@example.eol/some_path'
    @params = '?param1=1&param2=something&param3=1and2'
  end

  describe '#uri_remove_param' do
    it 'should return same url if there are no params given' do
      expect(EOLWebService.uri_remove_param(@url)).to eq(@url)
      expect(EOLWebService.uri_remove_param(@url + @params)).to eq(@url + @params)
    end

    it 'should remove any parameter' do
      url = @url + @params
      expect(EOLWebService.uri_remove_param(url, 'param1')).to eq(@url + '?param2=something&param3=1and2')
      expect(EOLWebService.uri_remove_param(url, 'param2')).to eq(@url + '?param1=1&param3=1and2')
      expect(EOLWebService.uri_remove_param(url, 'param3')).to eq(@url + '?param1=1&param2=something')
    end
    
    it 'should remove any parameter with escaped amps' do
      url = @url + @params.gsub('&', '&amp;')
      expect(EOLWebService.uri_remove_param(url, 'param1')).to eq(@url + '?param2=something&amp;param3=1and2')
      expect(EOLWebService.uri_remove_param(url, 'param2')).to eq(@url + '?param1=1&amp;param3=1and2')
      expect(EOLWebService.uri_remove_param(url, 'param3')).to eq(@url + '?param1=1&amp;param2=something')
    end

    it 'should remove more than one parameter' do
      url = @url + @params
      expect(EOLWebService.uri_remove_param(url, ['param1', 'param3'])).to eq(@url + '?param2=something')
    end

    it 'should remove ? at the end of url if no params left' do
      url = @url + @params
      expect(EOLWebService.uri_remove_param(url, ['param1', 'param2', 'param3'])).to eq(@url)
    end
  end

  describe '#url_accepted?' do
    it 'accepts good URLs' do
      stub_request(:head, "http://eol.org/").to_return(status: 200)
      expect(EOLWebService.url_accepted?('http://eol.org')).to eq(true)
    end

    it 'accepts https URLs' do
      stub_request(:head, "https://eol.org").to_return(status: 200)
      expect(EOLWebService.url_accepted?('https://eol.org')).to eq(true)
    end

    it 'rejects bad URLs' do
      stub_request(:head, "http://this.site.doesnt.exist").to_return(status: 404)
      expect(EOLWebService.url_accepted?(nil)).to eq(false)
      expect(EOLWebService.url_accepted?('')).to eq(false)
      expect(EOLWebService.url_accepted?('http://')).to eq(false)
      expect(EOLWebService.url_accepted?('http://this.site.doesnt.exist')).to eq(false)
    end

    it 'accepts redirects' do
      stub_request(:head, "http://this.is.a.redirect").to_return(status: 302, headers: { location: 'http://eol.org' } )
      stub_request(:head, "http://eol.org").to_return(status: 200)
      expect(EOLWebService.url_accepted?('http://this.is.a.redirect')).to eq(true)
    end
  end

end
