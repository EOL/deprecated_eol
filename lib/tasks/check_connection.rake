require 'lib/check_connection.rb'

desc 'Check that all of the expected attributes are valid on all the expected models'
task :check_connection => :environment do
  puts "Checking all attributes on all models that have an instance:"
  puts CheckConnection.all_instantiable_models.join("\n")
  puts "Done."
end

desc 'Rebuilds the class that checks the connection (redirect output to that file after confirming it is okay), using the latest models and attributes'
task :rebuild_connection_test => :environment do
  a = ActiveRecord::Base.connection.tables.map(&:singularize).map(&:camelize).map do |n|
    Kernel.const_get(n) rescue nil
  end.compact
  s = "class CheckConnection\n"
  s += "  def self.all_instantiable_models\n"
  s += "    a = []\n"
  a.each do |k|
    s += "    i = #{k.class_name}.first\n"
    k.column_names.each do |cn|
      s += "    i.#{cn} if i\n"
    end
    s += "    a << '#{k.class_name}' if i\n"
  end
  s += "    return a\n"
  s += "  end\n"
  s += "end\n"
  File.open("#{RAILS_ROOT}/lib/check_connection.rb", 'w') {|f| f.write(s) }
end
