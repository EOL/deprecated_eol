class FacebookController < ApplicationController

  layout nil

  # GET /facebook
  def index
    # Not doing anything at the moment
  end

  # GET /facebook/channel
  # @see channelUrl setting in https://developers.facebook.com/docs/reference/javascript/
  def channel
    respond_to do |format|
      format.html do
        cache_expire = 31536000 # 365 days in milliseconds
        response.headers["Pragma"] = "public"
        response.headers["Cache-Control"] = "max-age=#{cache_expire}"
        response.headers["Expires"] = Time.at(Time.now.to_i + cache_expire).strftime("%a, %d %b %Y %T %Z")
        render text: '<script src="//connect.facebook.net/en_US/all.js"></script>'
      end
    end
  end

end
