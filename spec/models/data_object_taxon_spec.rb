require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../scenario_helpers'

# Handles the associations between a data object and its taxon concepts.
describe DataObjectTaxon do

  before(:all) do
    # Mini-foundation. Perhaps we should extract this as a method in the spec helper:
    DataType.create_defaults
    License.create_defaults
    CuratorLevel.create_defaults
    Vetted.create_defaults
    Visibility.create_defaults
    Activity.create_defaults
    ChangeableObjectType.create_defaults

    @master = gen_curator(curator_level: CuratorLevel.master)
    @curator = gen_curator(curator_level: CuratorLevel.full)
    @dohe_he = HierarchyEntry.gen
    @dohe = DataObjectsHierarchyEntry.gen(vetted: Vetted.trusted,
                                          visibility: Visibility.visible,
                                          hierarchy_entry: @dohe_he)
    @hide_reason = :foo #TODO
    @cdohe_he = HierarchyEntry.gen
    @cdohe = CuratedDataObjectsHierarchyEntry.gen(user: @curator,
                                                  vetted: Vetted.unknown,
                                                  visibility: Visibility.invisible,
                                                  hierarchy_entry: @cdohe_he)
    @untrust_reason = :bar #TODO
    @taxon = TaxonConcept.gen(published: false)
    @udo = UsersDataObject.gen(vetted: Vetted.untrusted,
                               visibility: Visibility.preview,
                               taxon_concept: @taxon)
    @dohe_dot = DataObjectTaxon.new(@dohe)
    @cdohe_dot = DataObjectTaxon.new(@cdohe)
    @udo_dot = DataObjectTaxon.new(@udo)
  end

  it 'should know its data object' do
    @dohe_dot.data_object.should == @dohe.data_object
    @cdohe_dot.data_object.should == @cdohe.data_object
    @udo_dot.data_object.should == @udo.data_object
  end

  it 'should know its taxon concept' do
    @dohe_dot.taxon_concept.should == @dohe.taxon_concept
    @cdohe_dot.taxon_concept.should == @cdohe.taxon_concept
    @udo_dot.taxon_concept.should == @udo.taxon_concept
  end

  it 'should know if it was added by a curator' do
    @dohe_dot.by_curated_association?.should_not be_true
    @cdohe_dot.by_curated_association?.should be_true
    @cdohe_dot.associated_by_curator.should == @cdohe.user
    @udo_dot.by_curated_association?.should_not be_true # Because the user isn't a curator.
  end

  it 'should know its vetted state' do
    @dohe_dot.vetted.should == @dohe.vetted
    @cdohe_dot.vetted.should == @cdohe.vetted
    @udo_dot.vetted.should == @udo.vetted
  end

  it 'should know its visibility' do
    @dohe_dot.visibility.should == @dohe.visibility
    @cdohe_dot.visibility.should == @cdohe.visibility
    @udo_dot.visibility.should == @udo.visibility
  end

  it 'should be curatable' do
    # I don't care about all the variants for this one.
    %w(trust untrust show hide unreviewed).each do |cmd|
      @dohe_dot.respond_to?(cmd.to_sym).should be_true
    end
  end

  it 'should know any reasons given for hiding' do
    $FOO = true
    @cdohe_reasons = [UntrustReason.gen, UntrustReason.gen]
    cal = CuratorActivityLog.gen(data_object_guid: @cdohe.guid,
                                 changeable_object_type: ChangeableObjectType.curated_data_objects_hierarchy_entry,
                                 activity: Activity.hide,
                                 hierarchy_entry: @cdohe.hierarchy_entry)
    cal.untrust_reasons = @cdohe_reasons # Yes, really, it's called 'untrust reasons' on CAL.  :|
    cal.save!
    @cdohe_dot.hide_reason_ids.sort.should == @cdohe_reasons.map(&:id).sort
  end

  it 'should know any reasons given for untrusting' do
    @udo_reasons = [UntrustReason.gen, UntrustReason.gen]
    cal = CuratorActivityLog.gen(data_object_guid: @udo.guid,
                                 changeable_object_type: ChangeableObjectType.users_data_object,
                                 activity: Activity.untrusted)
    cal.untrust_reasons = @udo_reasons
    cal.save!
    @udo_dot.untrust_reason_ids.sort.should == @udo_reasons.map(&:id).sort
  end

  it 'should know its italicized name' do
    @dohe_dot.italicized_name.should == @dohe.hierarchy_entry.italicized_name
    @cdohe_dot.italicized_name.should == @cdohe.hierarchy_entry.italicized_name
    @udo_dot.italicized_name.should == @udo.taxon_concept.title
  end

  it 'should get its name (object) from hierarchy_entry' do
    @cdohe_dot.name.should == @cdohe.hierarchy_entry.name
  end

  it 'should know if it is a users data object' do
    @dohe_dot.users_data_object?.should_not be_true
    @cdohe_dot.users_data_object?.should_not be_true
    @udo_dot.users_data_object?.should be_true
  end

  it 'should know if it is published' do
    @dohe.hierarchy_entry.should_receive(:published).and_return(1)
    @cdohe.hierarchy_entry.should_receive(:published).and_return(2)
    @udo.taxon_concept.should_receive(:published).and_return(3)
    @dohe_dot.published.should == 1
    @cdohe_dot.published.should == 2
    @udo_dot.published.should == 3
  end

  it 'should know its hierarchy' do
    @dohe.hierarchy_entry.should_receive(:hierarchy).and_return(1)
    @cdohe.hierarchy_entry.should_receive(:hierarchy).and_return(2)
    entry = mock_model(HierarchyEntry)
    @udo.taxon_concept.should_receive(:entry).and_return(entry)
    entry.should_receive(:hierarchy).and_return(3)
    @dohe_dot.hierarchy.should == 1
    @cdohe_dot.hierarchy.should == 2
    @udo_dot.hierarchy.should == 3
  end

  it 'should use its hierarchy entry for an id' do
    @dohe_dot.id.should == @dohe.hierarchy_entry.id
    @cdohe_dot.id.should == @cdohe.hierarchy_entry.id
  end

  it 'should use its UsersDataObject for an id, if no hierarchy_entry' do
    @udo_dot.id.should == @udo.id
  end

  it 'should be deletable by a master curator if its curated' do
    @cdohe_dot.can_be_deleted_by?(@master).should be_true
  end

  it 'should be deletable by a full curator if its curated by that user' do
    @cdohe_dot.can_be_deleted_by?(@curator).should be_true
  end

  it 'should NOT be deletable by a full curator if it was NOT curated by that user' do
    curator = gen_curator(curator_level: CuratorLevel.full)
    @cdohe_dot.can_be_deleted_by?(curator).should_not be_true
  end

  it 'should NOT be deletable if it was NOT curated' do
    @dohe_dot.can_be_deleted_by?(@master).should_not be_true
    @udo_dot.can_be_deleted_by?(@master).should_not be_true
  end
  
end
