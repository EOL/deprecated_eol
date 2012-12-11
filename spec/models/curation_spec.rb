require File.dirname(__FILE__) + '/../spec_helper'

describe Curation do

  def association(vetted, visibility)
    DataObjectsHierarchyEntry.delete_all(:data_object_id => @data_object.id, :hierarchy_entry_id => @entry.id)
    dohe = DataObjectsHierarchyEntry.create(:data_object => @data_object, :hierarchy_entry => @entry,
                                            :visibility => Visibility.send(visibility), :vetted => Vetted.send(vetted))
    # TODO - this is awful, awful, awful, awful!  ...But, without re-writing a bunch of delicate code, we must:
    # (this is essentially stolen from DataObject#curated_hierarchy_entries)
    he = dohe.hierarchy_entry # I'm calling this do we don't get the @entry instance, which I don't want to change...
    he.vetted = dohe.vetted
    he.visibility = dohe.visibility
    he.name = @name
    he.taxon_concept = @taxon_concept
    he # I felt dirty just writing that block of code.  :(
  end

  def find_association
    DataObjectsHierarchyEntry.find(@data_object, @entry)
  end

  before(:all) do
    load_foundation_cache
    @user = User.gen(:curator_level => CuratorLevel.full, :credentials => 'whatever', :curator_scope => 'fun')
    @taxon_concept = TaxonConcept.gen # This is really only used for the id.
    @name = Name.gen(:string => 'this does not matter for these specs')
    @entry = HierarchyEntry.gen
    @data_object = DataObject.gen
    # TODO - I think these should be generalized:
    @misidentified = UntrustReason.misidentified
    @incorrect = UntrustReason.incorrect
    @poor = UntrustReason.poor
    @duplicate = UntrustReason.duplicate
  end

  before(:each) do
    @comment = Comment.gen
  end

  # TODO - Evaluate whether we should have any additional validations.

  # TODO - we should be testing various kinds of associations, unforunately: DOHE, CDOHE, UsersDatos...

  it 'should make visibility hidden if curated as Untrusted' do
    curation = Curation.new(
      :user => @user,
      :association => association(:trusted, :visible),
      :data_object => @data_object,
      :vetted_id => Vetted.untrusted.id,
      :visibility_id => Visibility.visible.id, # Note we *say* visible, here
      :curation_comment => @comment
    )
    find_association.visibility.should == Visibility.invisible
  end

  it 'should fail to trust an untrusted association and keep it hidden without hide reasons' do
    lambda do
      curation = Curation.new(
        :user => @user,
        :association => association(:untrusted, :invisible),
        :data_object => @data_object,
        :vetted_id => Vetted.trusted.id
      )
    end.should raise_error
  end

  it 'should fail to unreview an untrusted association and keep it hidden without hide reasons' do
    lambda do
      curation = Curation.new(
        :user => @user,
        :association => association(:untrusted, :invisible),
        :data_object => @data_object,
        :vetted_id => Vetted.unknown.id
      )
    end.should raise_error
  end

  it 'should do nothing if nothing changed'

  it 'should do nothing if the object is in preview'

  it 'should hide with CuratorActivityLog if needed'
  it 'should show with CuratorActivityLog if needed'

  it 'should untrust with CuratorActivityLog if needed'
  it 'should trust with CuratorActivityLog if needed'
  it 'should unreview with CuratorActivityLog if needed'

  it 'should NOT untrust if no reason or comment given'
  it 'should NOT hide if no reason or comment given'
  it 'should NOT unreview if no reason or comment given'

  it 'should raise an exception if bad vetted id given'
  it 'should raise an exception if bad visibility id given'

  # TODO - WHY?  These should be generalized.
  it 'should log misidentified reason'
  it 'should log incorrect reason'
  it 'should log poor reason'
  it 'should log duplicate reason'

  # TODO - LAME. It should call TaxonConceptCacheClearing, which should be updated to handle the things in the
  # controller.
  it 'should have clearables'

end
# *Have truer words ever been spoken?
