module ActiveRecord
  class Base
    # EOL: the change here is to send along the preload options
    def self.preload_associations(instances, associations, preload_options = {})
      new_options = {}
      if preload_options && preload_options[:select]
        new_options[:select] = preload_options[:select].dup
      end
      ActiveRecord::Associations::Preloader.new(instances, associations, new_options).run
    end
  end
end
