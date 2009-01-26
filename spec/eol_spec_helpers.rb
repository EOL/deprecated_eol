module EOL::Spec
  module Helpers

    # returns an Array of constants for all of our model classes (classes defined in app/models)
    def all_model_classes
      path_to_models = File.expand_path File.join(RAILS_ROOT, 'app', 'models')
      # the grep command returns something like this for each class:
      #   app/models/error_log.rb:class ErrorLog < ActiveRecord\n
      `grep -Pro 'class (\\w+) < (\\w+)' '#{path_to_models}'`.split("\n").map { |grep_string|
        klass, superclass = /class (\w+) < (\w+)/.match(grep_string).captures
        superclass.constantize # need to touch superclass - needs to be loaded before klass is constantized
        klass
      }.
        sort.uniq.map { |class_name|
          begin
            class_name.constantize
          rescue
            puts "all_model_classes: couldn't load #{ class_name }"
            nil
          end
      }.
        compact
    end

  end
end
