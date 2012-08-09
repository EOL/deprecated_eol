module ActiveRecord
  class Base
    # EOL: the change here is to send along the preload options
    def self.preload_associations(instances, associations, preload_options = {})
      ActiveRecord::Associations::Preloader.new(instances, associations, preload_options).run
    end
  end
end
