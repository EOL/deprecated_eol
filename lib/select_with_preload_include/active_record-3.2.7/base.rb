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
    
    # EOL: giving the function to instances too
    def preload_associations(associations, preload_options = {})
      self.class.preload_associations(self, associations, preload_options)
    end
  end
end
