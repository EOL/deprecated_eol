require File.dirname(__FILE__) + '/../spec_helper'

describe Factory do

  # using for now, in place of all_model_classes
  def self.some_model_classes
    [ TaxonConcept, HierarchyEntry ]
  end

  # use all_model_classes if you want *all* ... all 97 of them  :)
  some_model_classes.each do |klass|
    it "should generate #{klass}" do
      3.times do
        lambda {
          Factory(klass.to_s.underscore.to_sym).should be_valid
        }.should change(klass, :count).by(3)
      end    
    end
  end

end
