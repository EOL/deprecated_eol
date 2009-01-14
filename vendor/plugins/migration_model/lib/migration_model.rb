module MigrationModel
  
  # returns a raw model class with no associations or validations
  # # or anything like that, so it's safe to use in migrations
  def migration_model model_class, &block
    safe_model = Class.new(model_class.superclass){ set_table_name model_class.table_name }
    safe_model.instance_eval(&block) if block
    safe_model
  end

  alias mm migration_model

end
