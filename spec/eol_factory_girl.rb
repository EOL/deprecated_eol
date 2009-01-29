# EOL tweaks / extensions to factory-girl
module EOL::FactoryGirlExtensions

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

# Extends all ActiveRecord::Base models with extensions 
# that integrate with factory-girl
ActiveRecord::Base.class_eval do
  extend EOL::FactoryGirlExtensions
end
