require File.dirname(__FILE__) + '/../../lib/eol_web_service'

describe EOLWebService do
  
  describe 'EOLWebService::valid_url?' do
    
    before(:each) do
      @valid_urls = ['http://www.github.com', 'http://github.com/dimus']
      #TODO valid https urls are invalid at the moment
      @invalid_urls = ['github.com', 'http://boguss.url', 'http://www.github.com dimus', 'https://gmail.com']
    end
    
    it 'should return true for valid urls' do
      @valid_urls.each do |a_url|
        EOLWebService::valid_url?(a_url).should be_true
      end
    end
    
    it 'should return false for invalid urls' do
      @invalid_urls.each do |a_url|
        EOLWebService::valid_url?(a_url).should be_false
      end
    end
  end
end

