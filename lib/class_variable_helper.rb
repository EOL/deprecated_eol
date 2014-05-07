module ClassVariableHelper

  def self.clear_class_variables
    ActiveRecord::Base.subclasses.each do |model|
      model.class_variables.each { |var| model.remove_class_variable(var) }
    end
  end

end
