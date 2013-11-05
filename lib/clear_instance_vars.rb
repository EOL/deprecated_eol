module ClearInstanceVars
  def clear_instance_variables
    @@ar_instance_vars ||= self.class.new.instance_variables << :@mock_proxy # For tests
    (instance_variables - @@ar_instance_vars).each do |ivar|
      remove_instance_variable(ivar)
    end
  end
end
