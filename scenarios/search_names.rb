# Creates the data required to do name searches for testing.
#
# ---
# dependencies: [ :foundation ]

require 'spec/eol_spec_helpers'
require 'spec/scenario_helpers'
# This gives us the ability to build taxon concepts:
include EOL::Spec::Helpers

results = {}

results[:name_for_all_types] = 'panda' # every item type should have a panda entry
results[:name_for_multiple_species] = 'tigger' # used for multiple taxa
results[:unique_taxon_name] = 'trigger' # the unique taxon name
results[:text_description] = 'Panda bears are furry'
results[:image_description] = 'Look at this crazy image of a panda'
results[:video_description] = 'Look at this crazy video of a panda'
results[:sound_description] = 'Listen to this crazy sound of a panda'
results[:panda] = build_taxon_concept(
  :common_names => [results[:name_for_all_types], results[:name_for_multiple_species], results[:unique_taxon_name]],
  :toc          => [{:toc_item => TocItem.overview, :description => results[:text_description]}],
  :images       => [{:description => results[:image_description]}],
  :youtube      => [{:description => results[:video_description]}],
  :sounds       => [{:description => results[:sound_description]}])
results[:panda].data_objects.each do |d|
  d.updated_at = Time.now
  d.save
  sleep(1) # this sleep and others in this file are to make sure we can reliably sort on date later
end


results[:tiger_name] = 'Tiger'
results[:tiger_tigger_name] = 'Tigger'
results[:tiger]      = build_taxon_concept(:common_names => [results[:tiger_name], results[:tiger_tigger_name]], :vetted => 'untrusted')
results[:tiger_lilly_name] = "#{results[:tiger_name]} lilly"
results[:tiger_lilly]      = build_taxon_concept(:common_names => [results[:tiger_lilly_name], 'Panther tigris'],
                                                 :vetted => 'unknown')
results[:tiger_moth_name] = "#{results[:tiger_name]} moth"
results[:tiger_moth]      = build_taxon_concept(:common_names => [results[:tiger_moth_name], 'Panther moth'])

# we want to be able to search on Bacteria and get something back with a totally different name on it
results[:tricky_search_suggestion] = 'Bacteria'
results[:suggested_taxon_name] = 'Something totally different'
results[:suggested_taxon] = build_taxon_concept(:scientific_name => results[:suggested_taxon_name],
                                         :common_names => [results[:suggested_taxon_name]])
SearchSuggestion.gen(:taxon_id => results[:suggested_taxon].id, :term => results[:tricky_search_suggestion])

# I'm only doing this so we get two results for Bacteria and not redirected.
results[:collection] = Collection.gen(:name => 'Bacteria parade')

results[:user1] = User.gen(:username => 'username1', :given_name => 'Username1', :family_name => 'lastname1')
results[:user2] = User.gen(:username => 'username2', :given_name => 'Panda', :family_name => 'lastname2')
sleep(1)
results[:collection] = Collection.gen(:name => 'Panda parade')
sleep(1)
results[:community] = Community.gen(:name => 'Panda bears of Woods Hole Community', :description => 'we are panda bears, and we live in Woods Hole')
# I don't want this collection name as I only want one entry for Panda in all filter categories
c = results[:community].collections.first
c.name = "Focus list for this test community"
c.save

results[:content_page] = ContentPage.gen(:page_name => "test_cms_page")

EOL::TestInfo.save('search_names', results)
