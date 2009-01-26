require File.dirname(__FILE__) + '/../spec_helper'

describe Factory do

  # we'll go thru and get all model classes ... for right now, tho, we'll 
  # set these manually to make it a bit easier to handle ...
  def self.all_model_classes
    [ TaxonConcept, HierarchyEntry ]
  end

  all_model_classes.each do |klass|
    it "should generate #{klass}" do
      3.times do
        lambda {
          Factory(klass.to_s.underscore.to_sym).should be_valid
        }.should change(klass, :count).by(3)
      end    
    end
  end

end
