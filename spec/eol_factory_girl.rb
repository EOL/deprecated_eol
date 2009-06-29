# EOL tweaks / extensions related to factory-girl ... could use some cleanup
module EOL::FactoryGirlActiveRecordBaseExtensions

  attr_accessor :factory_name

  # default factory name User => :user
  def factory_name
    @factory_name ||= self.name.underscore.downcase
  end

  # User.generate :username => 'bob'
  def generate *args
    Factory.create factory_name, *args
  end
  alias gen generate

  # User.build :username => 'bob'
  #
  # calls 'new' instead of 'create'
  def build *args
    Factory.build factory_name, *args
  end
  alias spawn build

  # User.valid_attributes
  # User.generator
  # Factory.attributes_for(:user)
  #
  # gets the attributes for a new model
  def valid_attributes
    Factory.attributes_for factory_name
  end
  alias generator valid_attributes

end

module EOL::FactoryGirlExtensions

  def self.included base
    begin
      base.class_eval {
        alias_method_chain :create, :duplicate_entry_checking
      }
    rescue NameError 
      puts "** WARNING: It seems you are trying to load 'spec/spec_helper' in development."
      puts "   Try it in test; not all required gems are loaded in this environment."
    end
  end

  def create_with_duplicate_entry_checking *args
    begin
      create_without_duplicate_entry_checking *args
    rescue Exception => ex
      if ex.message.include? "Mysql::Error: Duplicate entry '255'"
        puts "\nTrying to generate a Factory resulted in a Mysql::Error" + 
             "\nIt's likely that a table ran out of primary keys (255)"  + 
             "\nYou should try truncating these tables first.\n\n"
      end
      raise ex
    end
  end

end

# Extends all ActiveRecord::Base models with extensions 
# that integrate with factory-girl
ActiveRecord::Base.class_eval do
  extend EOL::FactoryGirlActiveRecordBaseExtensions
end
Factory.send :include, EOL::FactoryGirlExtensions
