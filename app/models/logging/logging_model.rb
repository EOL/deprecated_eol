# The abstract base class for all models requiring a connection to the logging database.
#
# Author: Preston Lee <preston.lee@openrain.com>
class LoggingModel < ActiveRecord::Base
 
  self.abstract_class = true
  
  # The connections for the logging database are defined in the "config/database.yml" file, and 
  # are all suffixed with "_logging" (development_logging, test_logging, etc)    
  use_db :suffix =>  '_logging'

  def self.create(opts = {})

    ##return unless $ENABLE_DATA_LOGGING  # TODO: can we uncomment this line to double snure that we don't log anything if not configured to do it!

    instance = self.new(opts)
    instance.created_at = Time.now if instance.respond_to? :created_at
    instance.updated_at = Time.now if instance.respond_to? :updated_at
    if self.connection.prefetch_primary_key?(self.table_name)
      instance.id = self.connection.next_sequence_value(self.sequence_name)
    end

    # HAAAAAACK:  TODO - is there a better way to get to this?
    instance.instance_eval { def attribs ; attributes_with_quotes ; end ; def cols ; quoted_column_names ; end }
    quoted_attributes = instance.attribs

    statement = if quoted_attributes.empty?
      self.connection.empty_insert_statement(self.table_name)
    else
      "INSERT DELAYED INTO #{self.quoted_table_name} " +
      "(#{instance.cols.join(', ')}) " +
      "VALUES(#{quoted_attributes.values.join(', ')})"
    end

    instance.id = self.connection.insert(statement, "#{self.name} Create",
      self.primary_key, instance.id, self.sequence_name)

    @new_record = false
    instance
  end

end
