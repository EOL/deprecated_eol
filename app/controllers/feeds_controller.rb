class FeedsController < ApplicationController
  def all
    feed = Atom::Feed.new do |f|
      f.title = "Example Feed"
    end
    render :text => feed.to_xml
  end
end