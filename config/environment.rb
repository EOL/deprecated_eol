# Load the rails application
require File.expand_path('../application', __FILE__)

module InitializerAdditions
  def self.add(name)
    file = File.join(File.dirname(__FILE__), "#{name}.rb")
    if File.exists?(file)
      begin
        require file
        puts "** LOADED: #{name} **"
      rescue LoadError
        puts "** WARNING: COULD NOT LOAD #{file} **"
      end
    else
      puts "++ No config for #{name} found, skipping."
    end
  end
end

InitializerAdditions.add("environments/#{Rails.env}_eol_org")
InitializerAdditions.add("environment_eol_org")
InitializerAdditions.add("environments/local")
EolUpgrade::Application.initialize!
