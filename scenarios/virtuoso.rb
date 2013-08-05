
$LOADING_BOOTSTRAP = true

# We turn off Solr and reindex the whole lot at the end - its faster that way
original_index_records_on_save_value = $INDEX_RECORDS_IN_SOLR_ON_SAVE
$INDEX_RECORDS_IN_SOLR_ON_SAVE = false

# Looking up the activity logs for comments is slow here as lots of comments
# are created in the bootstrap. They will get indexed en masse at the end of
# this scenario
$SKIP_CREATING_ACTIVITY_LOGS_FOR_COMMENTS = true

require Rails.root.join('spec', 'eol_spec_helpers.rb')
require Rails.root.join('spec', 'scenario_helpers.rb')
# This gives us the ability to recalculate some DB values:
include EOL::Data
# This gives us the ability to build taxon concepts:
include EOL::RSpec::Helpers

truncate_all_tables
drop_all_virtuoso_graphs
load_scenario_with_caching(:bootstrap)


50.times do
  build_taxon_concept
end


number_of_concepts = TaxonConcept.count


UserAddedData.skip_callback(:create, :after, :update_triplestore)
user_added_data_hashes = []
50.times do
  resource = Resource.gen
  user = User.gen
  10.times do
    taxon_concept = TaxonConcept.first(:offset => rand(number_of_concepts))
    target_taxon_concept = TaxonConcept.where("id != #{taxon_concept.id}").first(:offset => rand(number_of_concepts - 1))
    default_data_options = { :subject => taxon_concept, :resource => resource }
    10.times do
      measurement = DataMeasurement.new(default_data_options.merge(:predicate => 'http://eol.org/weight', :object => rand(10000).to_s, :unit => 'http://eol.org/g'))
      measurement.update_triplestore
      association = DataAssociation.new(default_data_options.merge(:object => target_taxon_concept, :type => 'http://eol.org/preys_on'))
      association.update_triplestore
      user_added_data_hashes << { :user => user, :subject => taxon_concept, :predicate => 'http://eol.org/length', :object => rand(10000).to_s }
    end
  end
end
UserAddedData.create(user_added_data_hashes)
UserAddedData.recreate_triplestore_graph



# delete all concepts with no hierarchy entries
TaxonConcept.all.each do |tc|
  if tc.hierarchy_entries.empty?
    TaxonConcept.delete(tc.id)
  end
end

make_all_nested_sets
rebuild_collection_type_nested_set
flatten_hierarchies

DataObject.connection.execute("UPDATE data_objects SET updated_at = DATE_SUB(NOW(), INTERVAL id HOUR)")
Comment.connection.execute("UPDATE comments SET updated_at = DATE_SUB(NOW(), INTERVAL id HOUR)")

EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
EOL::Solr::CollectionItemsCoreRebuilder.begin_rebuild

# Creating images for the march of life
RandomHierarchyImage.delete_all
TaxonConceptExemplarImage.delete_all
TaxonConcept.where('published = 1').each do |tc|
  if image = tc.data_objects.select{ |d| d.is_image? }.first
    if dohe = image.data_objects_hierarchy_entries.first
      RandomHierarchyImage.gen(:hierarchy => dohe.hierarchy_entry.hierarchy, :hierarchy_entry => dohe.hierarchy_entry, :data_object => image, :taxon_concept => tc);
      TaxonConceptExemplarImage.gen(:taxon_concept => tc, :data_object => image)
    end
  end
end

$INDEX_RECORDS_IN_SOLR_ON_SAVE = original_index_records_on_save_value
$SKIP_CREATING_ACTIVITY_LOGS_FOR_COMMENTS = false
$LOADING_BOOTSTRAP = false
