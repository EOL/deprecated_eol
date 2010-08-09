class RackBox

  # Custom RSpec matchers
  module Matchers

    def self.included base
      
      # this should really just be matcher(:foo){ ... }
      # but there's a bit of other meta logic to deal with here
      Object.send :remove_const, :RedirectTo if defined? RedirectTo
      undef redirect_to if defined? redirect_to

      # the actual matcher logic
      matcher(:redirect_to, base) do |response, url|
        return false unless response['Location']
        if url =~ /^\//
          # looking for a relative match, eg. should redirect_to('/login')
          relative_location = response['Location'].sub(/^https?:\/\//,'').sub(/^[^\/]*/,'')
          # ^ there's probably a helper on Rack or CGI to do this
          relative_location.downcase == url.downcase
        else
          response['Location'].downcase == url.downcase
        end
      end

    end

  end

end
