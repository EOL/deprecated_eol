# For use in a Rails 2.0.2 environment configuration.
#
# This assets_host implementation routes CSS and JS assets to static1 and static2
# respectively.
#
# All other assets are routed to static3 through to static10
# 
# At the time of this writing, Rails 2.3.0 has support for a custom asset host 
# object that responds to call. This class does not support that.
class StaticEolAssetHost
  
  def self.asset_host_proc
    Proc.new { |source| 
      file_path = source.split("?").first
      if file_path.ends_with?(".css")
        asset = 1
      elsif file_path.ends_with?(".js")
        asset = 2
      else
        asset = [3, 4, 5, 6, 7, 8, 9, 10].rand
      end
      "http://static#{asset}.eol.org" 
    }
  end
  
end

