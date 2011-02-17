# This is similar to the select_with_include gem: http://code.google.com/p/ar-select-with-include/
# As of Rails 2.1 eager loading associations happen in separate queries:
#   see: http://rails.rubyonrails.org/classes/ActiveRecord/AssociationPreload/ClassMethods.html
# This extentions is mean to allow a select statement when using the :include option on finds
## For Example:
##   DataObject.find(:last,
##                   :select => 'data_objects.id, data_objects.created_at, vetted.label, data_types.*',
##                   :include => [:vetted, :data_type])

Dir[File.join(File.dirname(__FILE__), 'select_with_preload_include/**/*.rb')].sort.each { |lib| require lib }