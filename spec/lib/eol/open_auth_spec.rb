require File.dirname(__FILE__) + '/../../spec_helper'

describe EOL::OpenAuth do

  describe '#self.config_file' do

    it 'should load YAML configuration file' do
      EOL::OpenAuth.config_file.should be_a(Hash)
    end

  end

  describe '#self.init' do

    before :each do
      stub_oauth_requests
      @oauth1_consumer = OAuth::Consumer.new(
        "key",
        "secret",
        { :site => "http://fake.oauth1.provider",
          :request_token_path => "/example/request_token",
          :access_token_path => "/example/access_token",
          :authorize_path => "/example/authorize" })
    end

    it 'should create instance of EOL::OpenAuth::Facebook' do
      EOL::OpenAuth.init('facebook', 'fake/callback/path').should be_a(EOL::OpenAuth::Facebook)
    end

    it 'should create instance of EOL::OpenAuth::Google' do
      EOL::OpenAuth.init('google', 'fake/callback/path').should be_a(EOL::OpenAuth::Google)
    end

    it 'should create instance of EOL::OpenAuth::Twitter' do
      OAuth::Consumer.should_receive(:new).and_return(@oauth1_consumer)
      EOL::OpenAuth.init('twitter', 'fake/callback/path').should be_a(EOL::OpenAuth::Twitter)
    end

    it 'should create instance of EOL::OpenAuth::Yahoo' do
      OAuth::Consumer.should_receive(:new).and_return(@oauth1_consumer)
      EOL::OpenAuth.init('yahoo', 'fake/callback/path').should be_a(EOL::OpenAuth::Yahoo)
    end

  end
end

