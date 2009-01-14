require File.expand_path(File.dirname(__FILE__) + "/valid_model_attributes")

# == Valid Model Builder
#
# This is a little trick I use for building valid instances of models
#
# This is a pretty conventional approach within the Rails and RSpec worlds,
# although there have been multiple different implementations
#
# The idea here is you should be able to say ModelName.create_valid on 
# any model to get a valid model, created in the database
#
# This approach typically assumes that the database is recreated 
# between each spec, so each spec starts with an empty database
#
# == Usage
#
# I'm tweaking the way I usually do this a little bit ... here's the usage:
#
#   User.new_valid                  # User.new {default valid options}
#   User.new_valid :name => 'bob'   # User.new {default valid options, using 'bob' for :name}
#   User.create_valid               # User.create {default valid options}
#   User.create_valid!              # User.create! {default valid options}
#   ValidAttributesFor.user         # returns the {default valid options} for User
#
#   # these call #create_valid on additional models *before* returning the .new_valid
#   # instance, however #create_valid is only run if the additional Model.count returns 0
#   # so this is useful for ensuring that there's atleast one instance of another model
#   User.new_valid :dependencies => :site
#   User.new_valid :dependencies => [:site, :dog]
#   User.new_valid :dependencies => %w(site dog)
#
# == How are these different from fixtures?
#
# Well, with fixtures, you commonly create abunchof fixtures and you need to open 
# up the fixtures just to figure out what's going on.  a lot of the data is hidden.
# Not so, with this method (altho it could be used in such a way).  Typical usage 
# with this setup is more like:
#
#   @bob = User.create_valid :name => 'bob'
#   @sally = @bob.friends.create :name => 'sally'
#   @bob.friends.should include(@sally)
#
# Here's what that would convetionally look like using fixtures:
#
#   users(:bob).friends.should include(users(:sally))
#
# See the difference!  Where in the world did :bob and :sally come from?
# And how did we know that they're friends???
#
# Please do *NOT* use these like fixtures!!!  Do *NOT* do this:
#
#   User.create_valid.friends.should include(Users.first)
#
# Your specs should *NOT* _rely_ on the valid attributes.  Never depend on them.
# Always assume that they could change at any time.  Relying on the valid attributes 
# will make your specs just as fragile as when using fixtures.  The only assumption
# can can be safely made is: Model#valid_attributes should be enough to create a 
# valid model (with the exception of dependencies [which should be created when 
# calling any of the _valid methods to create/get a valid model]).
#
# ValidModelBuilder is the module to be included into ActiveRecord::Base 
# to give models create_valid/new_valid methods
module ValidModelBuilder
  def self.included base
    base.extend self
  end
  
  def valid_attributes options = {}
    ValidAttributesFor.send(self.name.underscore).merge options
  end
    
  [ :new_valid, :create_valid, :create_valid! ].each do |method|
    define_method(method) do |*args|
      options = args.shift || {}
      options = valid_attributes.merge options
      dependencies = options.delete(:dependencies)
      create_dependencies dependencies
      if dependencies
        dependencies.each do |dependency|
          # options = { "#{dependency}_id".to_sym => 1 }.merge(options) #if self.respond_to?("#{dependency}_id".to_sym)
          # it's slower but ... grab the id of the first dependency object
          options = { "#{dependency}_id".to_sym => dependency.to_s.camelize.constantize.find(:first).id }.merge(options)
        end
      end
      send(method.to_s.sub('_valid',''), options)
    end
  end

  def create_dependencies dependencies = []
    unless dependencies.nil? or dependencies.empty?
      dependencies.each do |model_name|
        model_class = model_name.to_s.camelcase.constantize
        model_class.create_valid unless model_class.count > 0
      end
    end
  end
end

# Extends all ActiveRecord::Base models with create_valid and new_valid methods
ActiveRecord::Base.class_eval do
  include ValidModelBuilder
end
