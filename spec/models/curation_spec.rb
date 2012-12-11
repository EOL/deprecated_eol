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

  def should_do_nothing(assoc, &block)
    cal = CuratorActivityLog.last
    vis = assoc.visibility
    vet = assoc.vetted
    yield assoc
    find_association.visibility.should == vis
    find_association.vetted.should == vet
    CuratorActivityLog.last.should == cal
  end

  # TODO - move to helper. this would be handy for testing in many specs:
  # NOTE - this is not actually a great test, since it checks ALL activities, so your spec may or may not have
  # generated it. ...If that matters to you, clear out the log before your spec.
  def the_curation_activities_on(what)
    what.activity_log.map {|al| al['instance'] }.select {|i| i.is_a? CuratorActivityLog }.map {|cal| cal.activity.name }
  end

  before(:all) do
    load_foundation_cache
    @user = User.gen(:curator_level => CuratorLevel.full, :credentials => 'whatever', :curator_scope => 'fun')
    @taxon_concept = TaxonConcept.gen # This is really only used for the id.
    @name = Name.gen(:string => 'this does not matter for these specs')
    @entry = HierarchyEntry.gen
    # TODO - I think these should be generalized:
    @misidentified = UntrustReason.misidentified
    @incorrect = UntrustReason.incorrect
    @poor = UntrustReason.poor
    @duplicate = UntrustReason.duplicate
  end

  before(:each) do
    @data_object = DataObject.gen
    @comment = Comment.gen(:parent => @data_object)
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
    should_do_nothing(association(:untrusted, :invisible)) do |assoc|
      lambda do
        curation = Curation.new(
          :user => @user,
          :association => assoc,
          :data_object => @data_object,
          :vetted_id => Vetted.trusted.id
        )
      end.should raise_error
    end
  end

  it 'should fail to unreview an untrusted association and keep it hidden without hide reasons' do
    should_do_nothing(association(:untrusted, :invisible)) do |assoc|
      lambda do
        curation = Curation.new(
          :user => @user,
          :association => assoc,
          :data_object => @data_object,
          :vetted_id => Vetted.unknown.id
        )
      end.should raise_error
    end
  end

  it 'should do nothing if nothing changed' do
    should_do_nothing(association(:trusted, :visible)) do |assoc|
      curation = Curation.new(
        :user => @user,
        :association => assoc,
        :data_object => @data_object,
        :vetted_id => Vetted.trusted.id,
        :visibility_id => Visibility.visible.id
      )
    end
  end

  # TODO - really?  Really?  Nothing?!  No error or anything?!
  it 'should do nothing if the object is in preview' do
    should_do_nothing(association(:untrusted, :preview)) do |assoc|
      curation = Curation.new(
        :user => @user,
        :association => assoc,
        :curation_comment => @comment,
        :data_object => @data_object,
        :vetted_id => Vetted.trusted.id
      )
    end
  end

  it 'should hide with CuratorActivityLog if needed' do
    curation = Curation.new(
      :user => @user,
      :association => association(:trusted, :visible),
      :data_object => @data_object,
      :visibility_id => Visibility.invisible.id,
      :curation_comment => @comment
    )
    find_association.visibility.should == Visibility.invisible
    the_curation_activities_on(@data_object).should include("hide")
  end

  it 'should show with CuratorActivityLog if needed' do
    curation = Curation.new(
      :user => @user,
      :association => association(:trusted, :invisible),
      :data_object => @data_object,
      :visibility_id => Visibility.visible.id
    )
    find_association.visibility.should == Visibility.visible
    the_curation_activities_on(@data_object).should include("show")
  end

  it 'should untrust with CuratorActivityLog if needed' do
    curation = Curation.new(
      :user => @user,
      :association => association(:trusted, :invisible), # Not that it matters, but invisible causes less work here
      :curation_comment => @comment,
      :data_object => @data_object,
      :vetted_id => Vetted.untrusted.id
    )
    find_association.vetted.should == Vetted.untrusted
    the_curation_activities_on(@data_object).should include("untrusted")
  end

  it 'should trust with CuratorActivityLog if needed' do
    curation = Curation.new(
      :user => @user,
      :association => association(:unknown, :visible),
      :data_object => @data_object,
      :vetted_id => Vetted.trusted.id
    )
    find_association.vetted.should == Vetted.trusted
    the_curation_activities_on(@data_object).should include("trusted")
  end

  it 'should unreview with CuratorActivityLog if needed' do
    curation = Curation.new(
      :user => @user,
      :association => association(:trusted, :visible),
      :curation_comment => @comment,
      :data_object => @data_object,
      :vetted_id => Vetted.unknown.id
    )
    find_association.vetted.should == Vetted.unknown
    the_curation_activities_on(@data_object).should include("unreviewed")
  end

  it 'should NOT untrust if no reason or comment given' do
    should_do_nothing(association(:trusted, :invisible)) do |assoc|
      lambda {
        curation = Curation.new(
          :user => @user,
          :association => assoc,
          :data_object => @data_object,
          :vetted_id => Vetted.untrusted.id
        )
      }.should raise_error
    end
  end

  it 'should NOT hide if no reason or comment given' do
    should_do_nothing(association(:trusted, :visible)) do |assoc|
      lambda {
        curation = Curation.new(
          :user => @user,
          :association => assoc,
          :data_object => @data_object,
          :visibility_id => Visibility.invisible.id,
        )
      }.should raise_error
    end
  end

  # TODO - we could handle this with a pain-old #find in the controller, yeah?
  it 'should raise an exception if bad vetted id given' do
    should_do_nothing(association(:trusted, :visible)) do |assoc|
      lambda {
        curation = Curation.new(
          :user => @user,
          :association => assoc,
          :data_object => @data_object,
          :vetted_id => Vetted.last.id + 1,
        )
      }.should raise_error
    end
  end

  # TODO - we could handle this with a pain-old #find in the controller, yeah?
  it 'should raise an exception if bad visibility id given' do
    should_do_nothing(association(:trusted, :visible)) do |assoc|
      lambda {
        curation = Curation.new(
          :user => @user,
          :association => assoc,
          :data_object => @data_object,
          :visibility_id => Visibility.last.id + 1,
        )
      }.should raise_error
    end
  end

  it 'should log untrusted with both reasons' do
    Curation.new(
      :user => @user,
      :association => association(:trusted, :invisible), # Invisible ensures we don't also hide it.
      :data_object => @data_object,
      :vetted_id => Vetted.untrusted.id,
      :untrust_reason_ids => [@misidentified.id, @incorrect.id]
    )
    # NOTE - I'm not entirely comfortable with assuming the last log is the one we want, but hey:
    CuratorActivityLog.last.untrust_reasons.should include(@misidentified)
    CuratorActivityLog.last.untrust_reasons.should include(@incorrect)
  end

  it 'should log hidden with both reasons' do
    Curation.new(
      :user => @user,
      :association => association(:trusted, :visible),
      :data_object => @data_object,
      :visibility_id => Visibility.invisible.id,
      :hide_reason_ids => [@poor.id, @duplicate.id]
    )
    # NOTE - I'm not entirely comfortable with assuming the last log is the one we want, but hey:
    CuratorActivityLog.last.untrust_reasons.should include(@poor)
    CuratorActivityLog.last.untrust_reasons.should include(@duplicate)
  end

  # TODO - While this test is probably still going to hold, the failure should really be on the CuratorActivityLog,
  # and thus really doesn't need to be tested here.
  it 'should FAIL with bad untrust reasons (not working yet)' do
    should_do_nothing(association(:trusted, :invisible)) do |assoc| # Invisible ensures we don't also hide it.
      lambda {
        Curation.new(
          :user => @user,
          :association => assoc,
          :data_object => @data_object,
          :vetted_id => Vetted.untrusted.id,
          :untrust_reason_ids => [UntrustReason.last.id + 1]
        )
      }.should raise_error
    end
  end

  # TODO - While this test is probably still going to hold, the failure should really be on the CuratorActivityLog,
  # and thus really doesn't need to be tested here.
  it 'should FAIL with bad hide reasons (not working yet)' do
    should_do_nothing(association(:trusted, :visible)) do |assoc|
      lambda {
        $FOO = 1
        Curation.new(
          :user => @user,
          :association => assoc,
          :data_object => @data_object,
          :visibility_id => Visibility.invisible.id,
          :hide_reason_ids => [UntrustReason.last.id + 1]
        )
      }.should raise_error
    end
  end

  # TODO - LAME. It should call TaxonConceptCacheClearing, which should be updated to handle the things in the
  # controller.
  it 'should NOT have clearable associations for a trust' do # ...or any other curation, but I'll check one for now.
    curation = Curation.new(
      :user => @user,
      :association => association(:untrusted, :visible),
      :data_object => @data_object,
      :vetted_id => Vetted.trusted.id
    )
    curation.clearables.should be_empty
  end

  # TODO - LAME. It should call TaxonConceptCacheClearing, which should be updated to handle the things in the
  # controller.
  it 'should have clearable associations for a hide' do
    curation = Curation.new(
      :user => @user,
      :association => assoc = association(:trusted, :visible),
      :curation_comment => @comment,
      :data_object => @data_object,
      :visibility_id => Visibility.invisible.id
    )
    curation.clearables.should include(assoc)
  end

end
# *Have truer words ever been spoken?
