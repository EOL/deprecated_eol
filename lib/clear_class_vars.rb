module ClearClassVars
  def clear_class_variables
    class_variables.each do |var|
      remove_class_variable(var)
    end
  end
end
