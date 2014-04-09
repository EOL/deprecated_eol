require "spec_helper"

describe FacebookController do

  describe 'GET channel' do
    it 'should return script tag and custom headers required by channelURL of Facebook JSSDK' do
      # @see http://developers.facebook.com/docs/reference/javascript/ for more info on channelURL
      get :channel
      response.body.should == "<script src=\"//connect.facebook.net/en_US/all.js\"></script>"
      expire_time = Time.at(Time.now.to_i + 31536000)
      response.headers["Expires"].should =~ /#{expire_time.strftime("%b %Y")}/
    end
  end

end
