module Features
  module ApiHelpers

    def get_as_xml(path)
      visit(path)
      Nokogiri.XML(source)
    end

    def get_as_json(path)
      visit(path)
      JSON.parse(source)
    end

    def check_api_key(url, user)
      visit(url)
      log = ApiLog.last
      url.split(/[\?&]/).each do |url_part|
        log.request_uri.should match(url_part)
      end
      log.key.should_not be_nil
      log.key.should == user.api_key
      log.user_id.should == user.id
    end

  end
end
