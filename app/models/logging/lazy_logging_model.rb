class LazyLoggingModel < LoggingModel

  self.abstract_class = true

  def self.create(opts = {})

    # never create a Logging row when data logging is turned off
    return nil unless $ENABLE_DATA_LOGGING

    if opts[:user].is_a?(EOL::AnonymousUser)
      opts[:user] = nil
    end
    instance = self.new(opts)
    instance.created_at = Time.now if instance.respond_to? :created_at
    instance.updated_at = Time.now if instance.respond_to? :updated_at
    if self.connection.prefetch_primary_key?(self.table_name)
      instance.id = self.connection.next_sequence_value(self.sequence_name)
    end

    # Important that we have quoted attributes and column names:
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
