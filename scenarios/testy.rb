# Put a few taxa (all within a new hierarchy) in the database with a range of accoutrements
#
#   TODO add a description here of what actually gets created!
#
#   This description block can be viewed (as well as other information
#   about this scenario) by running:
#     $ rake scenarios:show NAME=bootstrap
#
#---

require Rails.root.join('spec', 'scenario_helpers')
# This gives us the ability to build taxon concepts:
include EOL::Builders
include ScenarioHelpers # Allows us to load other scenarios

def build_big_tc(testy)
  build_taxon_concept(
    :parent_hierarchy_entry_id => testy[:empty_taxon_concept].hierarchy_entries.first.id,
    :rank            => 'species',
    :canonical_form  => testy[:canonical_form],
    :ranked_canonical_form => testy[:ranked_canonical_form],
    :attribution     => testy[:attribution],
    :scientific_name => testy[:scientific_name],
    :italicized      => testy[:italicized],
    :iucn_status     => testy[:iucn_status],
    :gbif_map_id     => testy[:gbif_map_id],
    :map             => {:description => testy[:map_text]},
    :flash           => [{:description => testy[:video_1_text]}, {:description => testy[:video_2_text]}],
    :youtube         => [{:description => testy[:video_3_text]}],
    :comments        => [{:user => testy[:user], :body => testy[:comment_1]},
                         {:user => testy[:user], :body => testy[:comment_bad]},
                         {:user => testy[:user], :body => testy[:comment_2]}],
    :images          => [{:object_cache_url => testy[:image_1], :data_rating => 2},
                         {:object_cache_url => testy[:image_2], :data_rating => 3},
                         {:object_cache_url => testy[:image_untrusted], :vetted => Vetted.untrusted},
                         {:object_cache_url => testy[:image_3], :data_rating => 4},
                         {:object_cache_url => testy[:image_unknown_trust], :vetted => Vetted.unknown},
                         {}, {}, {}, {}, {}, {}], # We want more than 10 images, to test pagination, but the details don't mattr
    :toc             => [{:toc_item => testy[:overview], :description => testy[:overview_text]},
                         {:toc_item => testy[:brief_summary], :description => testy[:brief_summary_text]},
                         {:toc_item => testy[:education], :description => testy[:education_text]},
                         {:toc_item => testy[:toc_item_2]}, {:toc_item => testy[:toc_item_3]}, {:toc_item => testy[:toc_item_3]}]
  )
end

def build_tc_with_only_one_toc_item(type, testy)
  testy["only_#{type}".to_sym] = build_taxon_concept(:parent_hierarchy_entry_id => testy[:exemplar].id,
    :toc => [{:toc_item => testy[type.to_sym], :description => testy["#{type}_text".to_sym], :data_rating => 5}],
    comments: [], bhl: [], images: [], sounds: [], youtube: [], flash: [])
  last_toc_dato = DataObjectsTableOfContent.last.data_object
  CuratedDataObjectsHierarchyEntry.new(:data_object_id => last_toc_dato.id,
                                       :data_object_guid => last_toc_dato.guid,
                                       :hierarchy_entry_id => testy[:exemplar].entry.id,
                                       :visibility => Visibility.invisible,
                                       :vetted => Vetted.untrusted,
                                       :user_id => 1).save
end

def build_tc_with_one_image(testy, tc_name, img_name, options = {})
  options[:published] ||= 1
  options[:visibility] ||= Visibility.visible
  testy[tc_name] = build_taxon_concept(:images => {}, comments: [], bhl: [], toc: [], images: [], sounds: [],
                                       youtube: [], flash: [])
  testy[img_name] = DataObject.gen(:data_type_id => DataType.image.id, :data_rating => 0.1,
                                   :published => options[:published])
  dohe = DataObjectsHierarchyEntry.gen(:data_object => testy[img_name], :visibility => options[:visibility],
                                       :hierarchy_entry_id => testy[tc_name].entry.id)
  TaxonConceptExemplarImage.gen(:taxon_concept => testy[tc_name], :data_object => testy[img_name])
  testy[tc_name].reindex_in_solr
end

load_foundation_cache
raise "** ERROR: testy scenario didn't load the foundation cache" unless Vetted.trusted && Agent.iucn && Rank.order

ActiveRecord::Base.transaction do
  testy = {}

  testy[:exemplar] = build_taxon_concept(:id => 910093, comments: [], toc: [], images: [], sounds: [],
                                         youtube: [], flash: []) # That ID is one of the (hard-coded) exemplars.

  testy[:empty_taxon_concept] =
    build_taxon_concept(:images => [], :toc => [], :flash => [], :youtube => [], :comments => [], :bhl => [])

  testy[:overview]        = TocItem.overview
  testy[:overview_text]   = 'This is a test Overview, in all its glory'
  testy[:brief_summary]   = TocItem.brief_summary
  testy[:brief_summary_text] = 'This is a test brief summary.'
  testy[:comprehensive_description] = TocItem.comprehensive_description
  testy[:comprehensive_description_text] = 'This is a test comprehensive description.'
  testy[:distribution]    = TocItem.distribution
  testy[:distribution_text] = 'This is a test distribution text.'
  testy[:education]       = TocItem.education_resources
  testy[:education_text]  = 'This is a test education.'
  testy[:toc_item_2]      = TocItem.gen_if_not_exists(:view_order => 2, :label => "test toc item 2")
  testy[:toc_item_3]      = TocItem.gen_if_not_exists(:view_order => 3, :label => "test toc item 3")
  testy[:toc_item_4]      = TocItem.gen_if_not_exists(:view_order => 4, :label => "test toc item 4")
  testy[:canonical_form]  = FactoryGirl.generate(:species) + 'tsty'
  testy[:ranked_canonical_form] = FactoryGirl.generate(:species) + ' var. tsty'
  testy[:attribution]     = Faker::Eol.attribution
  testy[:common_name]     = Faker::Eol.common_name.firstcap + 'tsty'
  testy[:unreviewed_name] = Faker::Eol.common_name.firstcap + 'tsty'
  testy[:untrusted_name]  = Faker::Eol.common_name.firstcap + 'tsty'
  testy[:scientific_name] = "#{testy[:canonical_form]} #{testy[:attribution]}"
  testy[:italicized]      = "<i>#{testy[:canonical_form]}</i> #{testy[:attribution]}"
  testy[:iucn_status]     = FactoryGirl.generate(:iucn)
  testy[:gbif_map_id]     = '424242'
  testy[:map_text]        = 'Test Map'
  testy[:image_1]         = FactoryGirl.generate(:image)
  testy[:image_2]         = FactoryGirl.generate(:image)
  testy[:image_3]         = FactoryGirl.generate(:image)
  testy[:image_unknown_trust] = FactoryGirl.generate(:image)
  testy[:image_untrusted] = FactoryGirl.generate(:image)
  testy[:video_1_text]    = 'First Test Video'
  testy[:video_2_text]    = 'Second Test Video'
  testy[:video_3_text]    = 'YouTube Test Video'
  testy[:comment_1]       = 'This is totally awesome'
  testy[:comment_bad]     = 'This is totally inappropriate'
  testy[:comment_2]       = 'And I can comment multiple times'

  tc = build_big_tc(testy)

  testy[:id]            = tc.id
  # The curator factory cleverly hides a lot of stuff that User.gen can't handle:
  testy[:curator]       = build_curator(tc)
  # TODO - I am slowly trying to convert all of the above options to methods to make testing clearer:
  agent = testy[:curator].agent
  (testy[:common_name_obj], testy[:synonym_for_common_name], testy[:tcn_for_common_name]) =
    tc.add_common_name_synonym(testy[:common_name], :agent => agent, :language => Language.english,
                                                  :vetted => Vetted.trusted, :preferred => true)
  tc.add_common_name_synonym(testy[:unreviewed_name], :agent => agent, :language => Language.english,
                                                :vetted => Vetted.unknown, :preferred => false)
  tc.add_common_name_synonym(testy[:untrusted_name], :agent => agent, :language => Language.english,
                                                :vetted => Vetted.untrusted, :preferred => false)
  # References for overview text object
  overview = tc.data_objects.select{ |d| d.is_text? }.first
  overview.add_ref_with_published_and_visibility('A published visible reference for testing.',
    1, Visibility.visible)
  overview.add_ref_with_published_and_visibility('A published invisible reference for testing.',
    1, Visibility.invisible)
  overview.add_ref_with_published_and_visibility('An unpublished visible reference for testing.',
    0, Visibility.visible)
  overview.add_ref_with_published_and_visibility('A published visible reference with an invalid identifier for testing.',
    1, Visibility.visible).add_identifier('invalid', 'An invalid reference identifier.')
  overview.add_ref_with_published_and_visibility('A published visible reference with a DOI identifier for testing.',
    1, Visibility.visible).add_identifier('doi', '10.12355/foo/bar.baz.230')
  overview.add_ref_with_published_and_visibility('A published visible reference with a URL identifier for testing.',
    1, Visibility.visible).add_identifier('url', 'some/url.html')

  # And we want one comment that the world cannot see:
  Comment.find_by_body(testy[:comment_bad]).hide User.last
  testy[:user] = User.gen

  testy[:child1] = build_taxon_concept(:parent_hierarchy_entry_id => tc.hierarchy_entries.first.id, comments: [], toc: [],
                                       images: [], bhl: [], sounds: [], youtube: [], flash: [])
  testy[:child2] = build_taxon_concept(:parent_hierarchy_entry_id => tc.hierarchy_entries.first.id, comments: [], toc: [],
                                       images: [], bhl: [], sounds: [], youtube: [], flash: [])
  testy[:sub_child] = build_taxon_concept(:parent_hierarchy_entry_id => testy[:child1].hierarchy_entries.first.id, comments: [], toc: [],
                                          images: [], bhl: [], sounds: [], youtube: [], flash: [])

  testy[:good_title] = %Q{"Good title"}
  testy[:bad_title] = testy[:good_title].downcase
  testy[:taxon_concept_with_bad_title] = build_taxon_concept(:canonical_form => testy[:bad_title], comments: [], toc: [],
                                                             images: [], bhl: [], sounds: [], youtube: [], flash: [])

  testy[:taxon_concept_with_unpublished_iucn] = build_taxon_concept(comments: [], toc: [], images: [],
                                                                    bhl: [], sounds: [], youtube: [], flash: [])
  testy[:bad_iucn_value] = 'bad value'
  iucn_entry = build_iucn_entry(testy[:taxon_concept_with_unpublished_iucn], testy[:bad_iucn_value])
  iucn_entry.update_column(:published, 0)

  testy[:taxon_concept_with_no_common_names] = build_taxon_concept(
    :common_names => [],
    :toc => [ {:toc_item => TocItem.common_names} ], comments: [], images: [], bhl: [], sounds: [], youtube: [], flash: [])

  # Common names to be added to this one, but starts with none:
  testy[:taxon_concept_with_no_starting_common_names] = build_taxon_concept(
    :common_names => [],
    :toc => [ {:toc_item => TocItem.common_names} ], comments: [], images: [], bhl: [], sounds: [], youtube: [], flash: [])

  hierarchy = Hierarchy.default
  testy[:kingdom] = HierarchyEntry.gen(:hierarchy => hierarchy, :parent_id => 0)
  testy[:phylum ]= HierarchyEntry.gen(:hierarchy => hierarchy, :parent_id => testy[:kingdom].id)
  testy[:order] = HierarchyEntry.gen(:hierarchy => hierarchy, :parent_id => testy[:phylum].id)
  testy[:species] = build_taxon_concept(:parent_hierarchy_entry_id => testy[:order].id, :rank => 'species', comments: [], toc: [],
                                        images: [], bhl: [], sounds: [], youtube: [], flash: [])

  testy[:tcn_count] = TaxonConceptName.count
  testy[:syn_count] = Synonym.count
  testy[:name_count] = Name.count
  testy[:name_string] = "Piping plover"
  testy[:agent] = agent
  testy[:synonym] = tc.add_common_name_synonym(testy[:name_string], :agent => testy[:agent], :language => Language.english)
  testy[:name] = testy[:synonym].name
  testy[:tcn] = testy[:synonym].taxon_concept_name

  testy[:syn1] = tc.add_common_name_synonym('Some unused name', :agent => testy[:agent], :language => Language.english)
  testy[:tcn1] = TaxonConceptName.find_by_synonym_id(testy[:syn1].id)
  testy[:name_obj] ||= Name.last
  he2 = build_hierarchy_entry(1, tc, testy[:name_obj])
  # Slightly different method, in order to attach it to a different HE:
  testy[:syn2] = Synonym.generate_from_name(testy[:name_obj], :entry => he2, :language => Language.english, :agent => testy[:agent])
  testy[:tcn2] = TaxonConceptName.find_by_synonym_id(testy[:syn2].id)

  testy[:superceded_taxon_concept] = TaxonConcept.gen(:supercedure_id => testy[:id])
  testy[:superceded_comment] = Comment.gen(:parent_type => "TaxonConcept",
                                           :parent_id => testy[:superceded_taxon_concept].id,
                                           :body => "Comment on superceded taxon.",
                                           :user => User.first)
  testy[:unpublished_taxon_concept] = TaxonConcept.gen(:published => 0, :supercedure_id => 0)

  testy[:before_all_check] = User.gen(:username => 'testy_scenario')

  testy[:taxon_concept] = TaxonConcept.find(testy[:id]) # This just makes *sure* everything is loaded...

  testy[:no_language_in_toc] = build_taxon_concept(
    :toc => [{:toc_item => testy[:overview], :description => 'no language', :language_id => 0, :data_rating => 5},
             {:toc_item => testy[:brief_summary], :description => 'no language', :language_id => 0, :data_rating => 5}], comments: [],
    images: [], bhl: [], sounds: [], youtube: [], flash: [])

  build_tc_with_only_one_toc_item('overview', testy)
  build_tc_with_only_one_toc_item('brief_summary', testy)
  build_tc_with_only_one_toc_item('comprehensive_description', testy)
  build_tc_with_only_one_toc_item('distribution', testy)

  build_tc_with_one_image(testy, :has_one_image, :the_one_image)
  build_tc_with_one_image(testy, :has_one_unpublished_image, :the_one_unpublished_image, :published => 0)
  build_tc_with_one_image(testy, :has_one_hidden_image, :the_one_hidden_image, :visibility => Visibility.invisible)

  EOL::Data.flatten_hierarchies

  EOL::TestInfo.save('testy', testy)
end
