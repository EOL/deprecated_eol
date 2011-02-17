# The only change to Associations is to make references_eager_loaded_tables? return false
# when the :select option is included - thus utilizing the association_preload pathway
# We're now allowing :select with :include

module ActiveRecord
  module Associations
    private
      module ClassMethods
        private
          # EOL: this method was previously also checking:  || include_eager_select?(options, joined_tables)
          def references_eager_loaded_tables?(options)
            joined_tables = joined_tables(options)
            include_eager_order?(options, nil, joined_tables) || include_eager_conditions?(options, nil, joined_tables)
          end
      end
  end
end