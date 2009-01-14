def create_test_model(model_name, prefix="", suffix="", rails_env=RAILS_ENV)
  # puts "Creating test model '#{model_name}', :prefix => '#{prefix}', :suffix => '#{suffix}'"
  str = <<-EOF
  require "use_db"
  
    class #{model_name} < ActiveRecord::Base
      use_db :prefix => "#{prefix}", :suffix => "#{suffix}", :rails_env => "#{rails_env}"
    end
EOF
  eval(str)
end