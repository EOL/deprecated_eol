# This generator creates a new 'blackbox' spec, using RackBox
class BlackboxSpecGenerator < Rails::Generator::Base

  attr_accessor :name_of_spec_to_create, :name_of_spec_file_to_create

  # `./script/generate blackbox_spec foo` will result in:
  #
  #   runtime_args: ['foo']
  #   runtime_options: {:quiet=>false, :generator=>"blackbox_spec", :command=>:create, :collision=>:ask}
  #
  def initialize(runtime_args, runtime_options = {})
    setup_rails_to_run_blackbox_specs
    @name_of_spec_to_create      = runtime_args.join(' ')
    @name_of_spec_file_to_create = runtime_args.join('_').downcase
    super
  end

  # this should be done by ./script/generate blackbox
  def setup_rails_to_run_blackbox_specs
    spec_helper = File.join RAILS_ROOT, 'spec', 'spec_helper.rb'
    updated     = false
    if File.file? spec_helper
      source = File.read spec_helper
      unless source =~ /require .rackbox./
        if source =~ /require .spec\/rails./
          source.sub!(/require .spec\/rails./, "\\0\nrequire 'rackbox'") # inject a "require 'rackbox'" statement
          updated = true
        end
      end
      unless source =~ /config.use_blackbox/
        if source =~ /.configure do \|config\|/
          source.sub!(/.configure do \|config\|/, "\\0\n  config.use_blackbox = true") # inject config.use_blackbox
          updated = true
        end
      end
      if updated
        File.open(spec_helper, 'w'){|f| f << source }
        puts "     updated  spec/spec_helper.rb"
      end
    end
  end

  def manifest
    record do |m|
      m.directory 'spec/blackbox'
      m.template 'spec.erb', "spec/blackbox/#{ name_of_spec_file_to_create }_spec.rb" # what can i call to get args???
    end
  end
 
protected
 
  def banner
    "Usage: #{$0} blackbox_spec Name of Spec to Create"
  end
 
end
