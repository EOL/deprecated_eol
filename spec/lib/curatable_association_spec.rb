require "spec_helper"
require File.dirname(__FILE__) + '/../scenario_helpers'

describe 'Curating Associations' do

  before(:all) do
    truncate_all_tables

    load_scenario_with_caching(:testy)
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild

    @testy = EOL::TestInfo.load('testy')
    @taxon_concept = @testy[:taxon_concept]

    @curator         = @testy[:curator]
    @another_curator = create_curator
    @image_dato      = @taxon_concept.images_from_solr.last
    @hierarchy_entry = HierarchyEntry.gen

    @image_dato.add_curated_association(@curator, @hierarchy_entry)
    @dohe = DataObjectsHierarchyEntry.find_by_data_object_id(@image_dato.id)
    @cdohe = CuratedDataObjectsHierarchyEntry.find_by_hierarchy_entry_id_and_data_object_id(@hierarchy_entry.id,
                                                                                           @image_dato.id)
  end

  before(:each) do
    @dohe.vetted_id = Vetted.trusted.id
    @dohe.visibility_id = Visibility.visible.id
    @dohe.save!
  end

  # vetted_id: vetted_method,
  # visibility_id: visibility_method,
  # untrust_reason_ids: untrust_reason_ids,
  # curate_vetted_status: true,
  # curate_visibility_status: true,
  # curation_comment: 'test curation comment.',
  # curation_comment_status: true,
  # changeable_object_type: 'data_object'

  it 'should #trust a dohe' do
    @dohe.vetted_id = Vetted.untrusted.id # Current value IS trusted... blah.
    @dohe.save!
    @dohe.trust(@another_curator)
    @dohe.vetted_id.should == Vetted.trusted.id
  end

  it 'should #untrust a dohe' do
    @dohe.untrust(@another_curator)
    @dohe.vetted_id.should == Vetted.untrusted.id
  end

  it 'should #unreviewed a dohe' do
    @dohe.unreviewed(@another_curator)
    @dohe.vetted_id.should == Vetted.unknown.id
  end

  it 'should #inappropriate a dohe' do
    @dohe.inappropriate(@another_curator)
    @dohe.vetted_id.should == Vetted.inappropriate.id
  end

  it 'should #hide a dohe' do
    @dohe.hide(@another_curator)
    @dohe.visibility_id.should == Visibility.invisible.id
  end

  it 'should #show a dohe' do
    @dohe.visibility_id = Visibility.invisible.id
    @dohe.save!
    @dohe.show(@another_curator)
    @dohe.visibility_id.should == Visibility.visible.id
  end

  # NOTE - we could now check all of these methods on a cdohe... but the functionality of the library has been tested
  # on one model; as long as any other model that uses it has vis/vet ids, then it should also work.  I'm satisfied.

  # Also note, this lib used to save comments.  We chose to move that functionality to the controllers, since it's a
  # logging function, not a basic model function.

end
