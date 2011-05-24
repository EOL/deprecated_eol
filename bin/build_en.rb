#!/usr/local/env ruby

require 'ruby-debug'
require 'set'
require 'yaml'

def grepper(dir)
  `git grep I18n app/#{dir.chomp}`.split("\n").map do |m|
    found = []
    while m.sub!(/I18n.t\(?.([-_A-Za-z0-9]+)/, '')
      found << $1
    end
    found
  end.flatten
end

list = Set.new()
# Home Page, Taxon Page Overview, Collections Interface, Community Interface
%w[
  models
  controllers/application_controller.rb
  controllers/collections_controller.rb
  controllers/communities_controller.rb
  controllers/content_controller.rb
  controllers/taxa_controller.rb

  views/collection_items/_show.html.haml
  views/collections/show.html.haml
  views/collections/_show.html.haml
  views/communities/show.html.haml
  views/content/error.html.haml
  views/content/_error.html.haml
  views/content/index.html.haml
  views/data_objects/_attribution_minimal.html.haml
  views/feed_items/_index.html.haml
  views/feed_items/_form.html.haml
  views/layouts/v2/_global_navigation.html.haml
  views/layouts/v2/_search.html.haml
  views/members/_index.html.haml
  views/roles/_index.html.haml
  views/shared/_google_custom_search_params.html.haml
  views/taxa/_classifications_summary.html.haml
  views/taxa/_collections_summary.html.haml
  views/taxa/_communities_summary.html.haml
  views/taxa/_curators_summary.html.haml
  views/taxa/_iucn_status_summary.html.haml
  views/taxa/_media_summary.html.haml
  views/taxa/_media_thumbnail.html.haml
  views/taxa/_overview.html.haml
  views/taxa/show.html.haml
  views/taxa/_show.html.haml
  views/taxa/_text_summary.html.haml
  views/layouts/v2/basic.html.haml
  views/layouts/v2/communities.html.haml
  views/layouts/v2/application.html.haml
  views/layouts/v2/collections.html.haml
  views/layouts/v2/taxa.html.haml

].compact.each do |dir|
  list += grepper(dir)
end

en_file = YAML::load( File.open( 'config/locales/en.yml' ) )

new_hash = {"en" => {}}

# IGNORE THESE (unusual because the key name is set by a variable):
bad_keys = ["efault_alt_text", "18n"]

# ADD THESE:
list << "video_thumbnail_alt_text"
list << "sound_thumbnail_alt_text"
list << "image_thumbnail_alt_text"
list << "roles"

list.to_a.each do |k|
  if val = en_file["en"][k]
    new_hash["en"][k] = val
  elsif bad_keys.include? k
    # Do nothing... we know we want to avoid this one.
  else
    raise "No Key Found for '#{k}'."
  end
end

puts new_hash.to_yaml
