require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonPage do

  before(:all) do
    @taxon_concept = TaxonConcept.gen # Doesn't need to be anything fancy, here.
    @entry = HierarchyEntry.gen
    @user = User.gen
    @taxon_page = TaxonPage.new(@taxon_concept, @user)
    @taxon_page_with_entry = TaxonPage.new(@taxon_concept, @user, @entry)
  end

end
