module ActiveRecord
  class Migration
    class << self
      def method_missing(method, *arguments, &block)
       say_with_time "#{method}(#{arguments.map { |a| a.inspect }.join(", ")})" do
         arguments[0] = Migrator.proper_table_name(arguments.first) unless arguments.empty? || method == :execute
         if (self.respond_to?(:database_model))
           write "Using custom database model's connection (#{self.database_model}) for this migration"
           eval("#{self.database_model}.connection.send(method, *arguments, &block)")
         else
           ActiveRecord::Base.connection.send(method, *arguments, &block)
         end
       end
     end
   
     def uses_db?
       true
     end
   end
  end
end