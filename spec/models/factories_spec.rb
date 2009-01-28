require File.dirname(__FILE__) + '/../spec_helper'

describe Factory do

  ########## helpers #########

  # this isn't actually *all* model classes yet.
  #
  # for right now, i'm adding models in here, a few at a time, to make sure 
  # that the factories are implemented well
  #
  def self.model_classes
    [ MimeType, AgentRole, DataType, Agent, ContentPartner, CuratorActivity,
      Language, License, Visibility, Vetted, DataType, Role, User, ItemPage,
      DataObjectTag, DataObjectTags, DataObject, Comment, CuratorCommentLog,
      CuratorDataObjectLog, Hierarchy, HierarchyEntry, TaxonConcept, PageName,
      NormalizedLink, PublicationTitle, InfoItem, Taxon, DataObjectsTaxon,
      Contact, ContactSubject ].uniq

    # ... some to pick from (this isn't all of them) ...
    #
    # AgentContact, AgentsResource, AgentsHierarchyEntry, CuratorActivityLogDaily,
    # DataObjectsHarvestEvent, DataObjectsTableOfContent,
    # HarvestEvent, HierarchiesContent,
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

  factories.each do |factory, klass|
    it "should generate #{klass}" do
      klass.truncate
      lambda {   3.times { Factory(factory).should be_valid }   }.should change(klass, :count).by(3)
    end
  end

end
