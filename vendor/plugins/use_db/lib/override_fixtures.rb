# Override the rails fixtures to borrow the proper model's connection when inserting or deleting
# data whenever possible.

class Fixtures
  alias_method :rails_delete_existing_fixtures, :delete_existing_fixtures
  def delete_existing_fixtures    
    m = get_model
    #puts "Model: #{m}, class_name: #{@class_name}"
    return rails_delete_existing_fixtures unless m && m.respond_to?(:uses_db?) && m.uses_db?
    connection = m.connection
    connection.delete "DELETE FROM #{m.table_name}", 'Fixture Delete'
  end

  alias_method :rails_insert_fixtures, :insert_fixtures
  def insert_fixtures
    m = get_model
    return rails_insert_fixtures unless m && m.respond_to?(:uses_db?) && m.uses_db?
    connection = m.connection
    values.each do |fixture|
      #puts "Inserting fixtures into custom DB for #{connection.current_database}.#{m.table_name}: INSERT INTO #{m.table_name} (#{fixture.key_list}) VALUES (#{fixture.value_list})"
      connection.execute("INSERT INTO #{m.table_name} (#{fixture.key_list}) VALUES (#{fixture.value_list})", 'Fixture Insert')
    end
  end
  
private
  def get_model
    klass = eval(@class_name)
    return klass
  rescue
    return nil
  end
end