# To add blackbox testing to a Rails app,
# in your spec_helper.rb
#
#   require 'rackbox'
#
#   Spec::Runner.configure do |config|
#     config.use_blackbox = true
#   end
#
class RackBox
  class << self
    # the Rack appliction to do 'Black Box' testing against
    #
    # To set, in your spec_helper.rb or someplace:
    #   RackBox.app = Rack::Adapter::Rails.new :root => '/root/directory/of/rails/app', :environment => 'test'
    #
    # If not explicitly set, uses RAILS_ROOT (if defined?) and RAILS_ENV (if defined?)
    attr_accessor :app

    def app
      unless @app and @app.respond_to?:call
        if File.file? 'config.ru'
          @app = Rack::Builder.new { eval(File.read('config.ru')) }
        elsif defined?RAILS_ENV and defined?RAILS_ROOT
          raise "You need the Rack::Adapter::Rails to run Rails apps with RackBox." + 
                " Try: sudo gem install thin" unless defined?Rack::Adapter::Rails
          @app = Rack::Adapter::Rails.new :root => RAILS_ROOT, :environment => RAILS_ENV
        else
          raise "RackBox.app not configured."
        end
      end
      @app
    end
  end
end
