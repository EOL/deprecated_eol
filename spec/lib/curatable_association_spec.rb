require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../scenario_helpers'

describe 'Curating Associations' do

  before(:all) do
    truncate_all_tables

    load_scenario_with_caching(:testy)
    @testy = EOL::TestInfo.load('testy')
    @taxon_concept = @testy[:taxon_concept]

    @curator         = @testy[:curator]
    @another_curator = create_curator
    @image_dato      = @taxon_concept.images.last
    @hierarchy_entry = HierarchyEntry.gen

    @image_dato.add_curated_association(@curator, @hierarchy_entry)
    @dohe = DataObjectsHierarchyEntry.find_by_data_object_id(@image_dato.id)
    @cdohe = CuratedDataObjectsHierarchyEntry.find_by_hierarchy_entry_id_and_data_object_id(@hierarchy_entry.id,
                                                                                           @image_dato.id)
  end

  it 'should curate a dohe association' do
    feeditems_count = FeedItem.count
    @dohe.vetted_id = Vetted.trusted.id
    @dohe.visibility_id = Visibility.visible.id
    [Vetted.unknown.id, Vetted.untrusted.id, Vetted.trusted.id].each do |vetted_method|
      [Visibility.invisible.id, Visibility.inappropriate.id, Visibility.visible.id].each do |visibility_method|
        untrust_reason_ids = (vetted_method == Vetted.untrusted.id) ? [ UntrustReason.misidentified.id, UntrustReason.incorrect.id ] : []
        @dohe.curate(@another_curator, { :vetted_id => vetted_method,
                                         :visibility_id => visibility_method,
                                         :untrust_reason_ids => untrust_reason_ids,
                                         :curate_vetted_status => true, 
                                         :curate_visibility_status => true,
                                         :curation_comment => 'test curation comment.',
                                         :curation_comment_status => true,
                                         :changeable_object_type => 'data_object'
                                         })
        @dohe.vetted_id.should == vetted_method.to_i
        @dohe.visibility_id.should == visibility_method.to_i
        incr = (vetted_method == Vetted.untrusted.id) ? 2 : 1
        FeedItem.count.should == (feeditems_count += incr) #curation comment should be posted as a feed.
      end
    end
  end

  it 'should curate a cdohe association' do
    feeditems_count = FeedItem.count
    @cdohe.vetted_id = Vetted.trusted.id
    @cdohe.visibility_id = Visibility.visible.id
    [Vetted.unknown.id, Vetted.untrusted.id, Vetted.trusted.id].each do |vetted_method|
      [Visibility.invisible.id, Visibility.inappropriate.id, Visibility.visible.id].each do |visibility_method|
        untrust_reason_ids = (vetted_method == Vetted.untrusted.id) ? [ UntrustReason.misidentified.id, UntrustReason.incorrect.id ] : []
        @cdohe.curate(@another_curator, { :vetted_id => vetted_method,
                                          :visibility_id => visibility_method,
                                          :untrust_reason_ids => untrust_reason_ids,
                                          :curate_vetted_status => true, 
                                          :curate_visibility_status => true,
                                          :curation_comment => 'test curation comment.',
                                          :curation_comment_status => true,
                                          :changeable_object_type => 'curated_data_objects_hierarchy_entry'
                                          })
        @cdohe.vetted_id.should == vetted_method.to_i
        @cdohe.visibility_id.should == visibility_method.to_i
        incr = (vetted_method == Vetted.untrusted.id) ? 2 : 1
        FeedItem.count.should == (feeditems_count += incr)
      end
    end
  end

  it 'should add untrust reasons comment and save untrust reasons when curated as untrusted' do
    feeditems_count = FeedItem.count
    ahur_count = ActionsHistoriesUntrustReason.count
    # curate association in dohe
    @dohe.vetted_id = Vetted.trusted.id
    untrust_reason_ids = [ UntrustReason.misidentified.id, UntrustReason.incorrect.id ]
    @dohe.curate(@another_curator, { :vetted_id => Vetted.untrusted.id,
                                     :untrust_reason_ids => untrust_reason_ids,
                                     :curate_vetted_status => true,
                                     :changeable_object_type => 'data_object'
                                     })
    @dohe.untrusted?.should eql(true)
    FeedItem.count.should == (feeditems_count += 1)
    ActionsHistoriesUntrustReason.count.should == (ahur_count += 2)
    # curate association in cdohe
    @cdohe.vetted_id = Vetted.trusted.id
    untrust_reason_ids = [ UntrustReason.duplicate.id, UntrustReason.poor.id ]
    @cdohe.curate(@another_curator, { :vetted_id => Vetted.untrusted.id,
                                      :untrust_reason_ids => untrust_reason_ids,
                                      :curate_vetted_status => true,
                                      :changeable_object_type => 'curated_data_objects_hierarchy_entry'
                                      })
    @cdohe.untrusted?.should eql(true)
    FeedItem.count.should == (feeditems_count + 1)
    ActionsHistoriesUntrustReason.count.should == (ahur_count + 2)
  end

  it 'should add a curation comment to an association' do
    feeditems_count = FeedItem.count
    # add curator comment to association in dohe
    curation_comment = "test curation comment for dohe"
    @dohe.curate(@another_curator, { :curation_comment => curation_comment,
                                     :curation_comment_status => true,
                                     :changeable_object_type => 'data_object'
                                     })
    FeedItem.count.should == (feeditems_count += 1)
    #  add curator comment to association in cdohe
    curation_comment = "test curation comment for cdohe"
    @cdohe.curate(@another_curator, { :curation_comment => curation_comment,
                                      :curation_comment_status => true,
                                      :changeable_object_type => 'curated_data_objects_hierarchy_entry'
                                      })
    FeedItem.count.should == (feeditems_count + 1)
  end
end