require File.dirname(__FILE__) + '/../spec_helper'

describe Synonym do
  before(:all) do
    Scenario.load :foundation
    @tc = build_taxon_concept
    @agent = Agent.last
    @lang = Language.english
  end

  describe "preferred=" do
    it "when preffered name is set for a synoym all other synonyms of this language should get set preferred to false" do
      syn1  = @tc.add_common_name_synonym("First name", @agent, :language => @lang)
      TaxonConceptName.find_by_synonym_id(syn1.id).preferred?.should be_true
      syn2 = @tc.add_common_name_synonym("Second name", @agent, :language => @lang)
      TaxonConceptName.find_by_synonym_id(syn2.id).preferred?.should be_false
      syn2.preferred = 1
      syn2.save!
      Synonym.find(syn2).preferred?.should be_true
      TaxonConceptName.find_by_synonym_id(syn2.id).preferred?.should be_true
      Synonym.find(syn1).preferred?.should be_false
      TaxonConceptName.find_by_synonym_id(syn1.id).preferred?.should be_false
    end
  end


end
