require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonConcept do

  scenario :foundation

  # Why am I loading so many fixtures in a unit testing suite?  ...Because TaxonConcept is unlike other models: there is really
  # nothing to it: just an ID and a wee bit of ancillary data. At the same time, TC is *so* vital to everything we do, that I wanted
  # to construct tests that really jog the model through all of its relationships.
  #
  # If you want to think of this as more of a "black-box" test, that's fine.  I chose to put it in the models directory because,
  # well, it isn't testing a website, and it IS testing a *model*, so it seemed a "better" fit here, even if it isn't perfect.
  before(:each) do
    Rails.cache.clear
    @canonical_form  = Faker::Eol.scientific_name
    @attribution     = Faker::Eol.attribution
    @common_name     = Faker::Eol.common_name.firstcap
    @scientific_name = "#{@canonical_form} #{@attribution}"
    @italicized      = "<i>#{@canonical_form}</i> #{@attribution}"
    @iucn_status     = Faker::Eol.iucn
    tc = build_taxon_concept(:rank            => 'species',
                             :canonical_form  => @canonical_form,
                             :attribution     => @attribution,
                             :scientific_name => @scientific_name,
                             :italicized      => @italicized,
                             :common_name     => @common_name,
                             :iucn_status     => @iucn_status)
    @id            = tc.id
    @curator       = Factory(:curator, :curator_hierarchy_entry => tc.entry)
    @taxon_concept = TaxonConcept.find(@id)
  end

  it 'should have different names for different detail levels' do
    concept = TaxonConcept.generate

    # trying to create a name ... seems to be *REALLY* hard to simply add a name to a TaxonConcept ...
    # tc.taxon_concept_names.create :name => Name.gen, :language => Language.gen, :preferred => true, :vern => 0, :source_hierarchy_entry_id => HierarchyEntry.gen.id
    # ^ adds a valid TaxonConceptName but #name returns '?-?' (whatever that means) and #names returns [] ?
    #
    # JRice reponse: adding a name to a TC is REALLY difficult.  You need to have HE models underneath, with the proper kinds of
    # names, PLUS a TaconConceptName that references the Name you've created on the HE. The Spec for Search (black-box) has a method
    # for accomplishing this; it is on our TODO list to move that out and improve it.
  end

  it 'should have a canonical form' do
    @taxon_concept.canonical_form.should == @canonical_form
  end

  it 'should have curators' do
    @taxon_concept.curators.map(&:id).should include(@curator.id)
  end

  it 'should have a scientific name (italicized for species)' do
    @taxon_concept.scientific_name.should == @italicized
  end

  it 'should have a common name' do
    @taxon_concept.common_name.should == @common_name
  end

  it 'should set the common name to the correct language' do
    lang = Language.gen(:label => 'Frizzban')
    user = User.gen(:language => lang)
    str  = 'Frebblebup'
    name = Name.gen(:string => str)
    TaxonConceptName.gen(:language => lang, :name => name, :taxon_concept => @taxon_concept)
    @taxon_concept.current_user = user
    @taxon_concept.common_name.should == str
  end

  it 'should let you get/set the current user' do
    user = User.gen
    @taxon_concept.current_user = user
    @taxon_concept.current_user.should == user
  end

  it 'should have an IUCN conservation status' do
    @taxon_concept.iucn_conservation_status.should == @iucn_status
  end

end
