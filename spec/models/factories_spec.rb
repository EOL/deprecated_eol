require File.dirname(__FILE__) + '/../spec_helper'

describe Factory do

  before :all do
    reset_auto_increment_on_tables_with_tinyint_primary_keys
  end

  # WHERE ARE THE EXAMPLES ???
  #
  # see the # spec # section below !

  ########## helpers #########

  # this isn't actually *all* model classes yet.
  #
  # for right now, i'm adding models in here, a few at a time, to make sure 
  # that the factories are implemented well
  #
  def self.model_classes
    [ MimeType, AgentRole, DataType, Agent, ContentPartner, CuratorActivity,
      LastCuratedDate, Language, License, Visibility, Vetted, DataType, Role, User,
      ItemPage, DataObjectTag, DataObjectTags, DataObject, Comment,
      CuratorCommentLog, CuratorDataObjectLog, Hierarchy, HierarchyEntry,
      TaxonConcept, PageName, NormalizedLink, PublicationTitle, InfoItem, Taxon,
      Contact, ContactSubject, ResourceStatus, RefIdentifierType, Audience,
      AgentDataType, AgentContactRole, ServiceType, ActionWithObject, ChangeableObjectType ].uniq
  end

  # gets the names of the factories for classes ( default: model_classes )
  #
  # returns the factory names & the classes themselves, eg: [ [:x, X], [:a, A] ]
  #
  def self.factories classes = model_classes
    model_classes.map {|klass| [ klass.to_s.underscore.to_sym, klass ] }
  end

  # returns the names of all of the factories defined in factories.rb
  def self.factories_defined
    factories = File.read(File.join(RAILS_ROOT, 'spec', 'factories.rb')).grep(/^Factory.define :(.*) do/){ |x| $1.to_sym }
    puts factories.inspect
    factories.map {|name| 
      begin
        [ name, name.to_s.classify.constantize ]
      rescue NameError
        puts "couldn't find constant #{ name.to_s.classify } for factory #{ name }"
        nil
      end
    }.compact
  end

  ########## spec ##########

  # q: what in the world does this do
  #
  # a: this makes sure that our factories work!  eventually this should
  #    run *all* of our factories.  right now, we have an array of 
  #    models (see #model_classes above) and, for each of those models, 
  #    we run its generator 3 times.  we specify that each of the 3 generated 
  #    models should be valid and 3 additional database records should exist.
  #
  #    why do we generate *3*?  all factories should be runnable multiple times.
  #    that means your factories need to account for things like unique fields!
  #
  #    Dog.gen should return a valid Dog
  #    Dog.gen should return *another* valid Dog (if need be, this Dog should have a unique name)
  #    Dog.gen should return another valid Dog, just to be sure that we can generate more than 2
  #
  #    i think that generating 3 models will catch some bugs that generating 2 models wouldn't,
  #    specifically with regards to uniqueness.
  #
  factories.each do |factory, klass|

    it "should generate #{klass}" do
      klass.truncate
      begin
        lambda {   3.times { klass.gen.should be_valid }   }.should change(klass, :count).by(3)
      rescue => ex
        raise "#{ klass }.gen blew up!  Maybe try calling #{ klass }.gen yourself in a console?  " + 
              "remember to require 'spec/spec_helper' to get all of the factories / etc.  \n\n" + 
              "this spec: spec/models/factories_spec.rb \n\n#{ ex }"
      end
    end

  end

end
