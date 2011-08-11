#!/usr/local/env ruby -KU

require 'ruby-debug'
require 'set'
require 'ya2yaml'
require 'yaml'
require 'yaml/encoding'

def create_initial_file(lang, list, master = {})

  target = "config/locales/initial/#{lang}-tmp.yml"
  puts "&& Writing #{target}..."

  source = YAML::load(File.open("config/locales/#{lang}.yml"))

  new_hash = {lang => {}}

  list.to_a.each do |k|
    if val = source[lang][k]
      new_hash[lang][k] = val
    elsif @bad_keys.include? k
      # Do nothing... we know we want to avoid this one.
    else
      if master == "DONT"
        # Do nothing... we don't care about missing keys for some files (qqq, for example)
      elsif master.has_key? k
        puts "** WARNING: No #{lang} key found for '#{k}'.  Faking it." if lang == 'en'
        new_hash[lang][k] = master[k]
      else
        puts "** WARNING: No #{lang} key found for '#{k}', and no master value either.  Leaving empty..."
        new_hash[lang][k] = "TODO"
      end
    end
  end

  File.open(target, "w") do |f|
    f.write(new_hash.ya2yaml)
  end

  puts "  ...done."

  return new_hash[lang]
end

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

%w[
  models

  views/layouts/v2

  views/activity_logs
  views/admins
  views/collection_items
  views/collections
  views/comments
  views/communities
  views/data_objects
  views/members
  views/search
  views/sessions
  views/taxa/details
  views/taxa/literature
  views/taxa/maps
  views/taxa/media
  views/taxa/names
  views/taxa/overviews
  views/taxa/resources
  views/taxa/trees
  views/taxa/updates
  views/taxa/worklist
  views/users

  controllers/admins_controller.rb
  controllers/application_controller.rb
  controllers/collection_items_controller.rb
  controllers/collections_controller.rb
  controllers/comments_controller.rb
  controllers/communities/collections_controller.rb
  controllers/content_controller.rb
  controllers/data_objects_controller.rb
  controllers/fckeditor_controller.rb
  controllers/hierarchy_entries_controller.rb
  controllers/members_controller.rb
  controllers/search_controller.rb
  controllers/sessions_controller.rb
  controllers/taxa/details_controller.rb
  controllers/taxa/literature_controller.rb
  controllers/taxa/maps_controller.rb
  controllers/taxa/media_controller.rb
  controllers/taxa/names_controller.rb
  controllers/taxa/overviews_controller.rb
  controllers/taxa/resources_controller.rb
  controllers/taxa/trees_controller.rb
  controllers/taxa/updates_controller.rb
  controllers/taxa/worklist_controller.rb
  controllers/taxa_controller.rb
  controllers/users/activities_controller.rb
  controllers/users/collections_controller.rb
  controllers/users/newsfeeds_controller.rb
  controllers/users_controller.rb

  views/administrator/curator/_user_row.html.haml
  views/content/_error.html.haml
  views/content/_march_of_life_item.html.haml
  views/content/donate.html.haml
  views/content/error.html.haml
  views/content/index.html.haml
  views/content/page.html.haml
  views/navigation/_browse_page.html.haml
  views/navigation/_node_name_page.html.haml
  views/navigation/_node_with_ancestry_page.html.haml
  views/shared/_add_to_my_collection.html.haml
  views/shared/_flash_messages.html.haml
  views/shared/_google_custom_search_params.html.haml
  views/shared/_item_summary_article.html.haml
  views/shared/_item_summary_collection.html.haml
  views/shared/_item_summary_media.html.haml
  views/shared/_item_summary_person.html.haml
  views/shared/_item_summary_taxon.html.haml
  views/shared/_join_eol.html.haml
  views/shared/_sort_by_date_form.html.haml
  views/taxa/_classification_selector.html.haml
  views/taxa/_classification_tree.html.haml
  views/taxa/_classifications_summary.html.haml
  views/taxa/_classifications_summary_minitree_node_with_children.html.haml
  views/taxa/_collections_summary.html.haml
  views/taxa/_collections_summary_empty.html.haml
  views/taxa/_curators_summary.html.haml
  views/taxa/_iucn_status_summary.html.haml
  views/taxa/_media_summary.html.haml
  views/taxa/_media_thumbnail.html.haml
  views/taxa/_overview_image_taxon_link.html.haml
  views/taxa/_recognised_by.html.haml
  views/taxa/_text_summary.html.haml
  views/taxa/content/_content_content_summary.html.haml

].compact.each do |dir|
  list += grepper(dir)
end

# ADD THESE:
list << "video_thumbnail_alt_text"
list << "sound_thumbnail_alt_text"
list << "image_thumbnail_alt_text"
list << "roles"

list << "view_article_source"
list << "view_image_source"

[:image, :sound, :article, :video].each do |type|
  list << "associated_with_#{type}_header"
end

(1..5).each do |n|
  list << "change_rating_to_#{n}_of_5"
end

(0..5).each do |n|
  list << "your_current_rating_#{n}_of_5"
end

[:newest, :rating, :status].each do |type|
  list << "sort_by_#{type}_option"
end

list << "license_all_rights_reserved"
list << "license_cc_by"
list << "license_cc_by_2_0"
list << "license_cc_by_2_5"
list << "license_cc_by_3_0"
list << "license_cc_by_nc"
list << "license_cc_by_nc_2_0"
list << "license_cc_by_nc_2_5"
list << "license_cc_by_nc_3_0"
list << "license_cc_by_nc_sa"
list << "license_cc_by_nc_sa_1_0"
list << "license_cc_by_nc_sa_2_0"
list << "license_cc_by_nc_sa_2_5"
list << "license_cc_by_nc_sa_3_0"
list << "license_cc_by_sa"
list << "license_cc_by_sa_1_0"
list << "license_cc_by_sa_2_0"
list << "license_cc_by_sa_2_5"
list << "license_cc_by_sa_3_0"
list << "license_gnu_fdl"
list << "license_gnu_gpl"
list << "license_not_applicable"
list << "license_public_domain"

list << "download_audio_mpeg"

[:all, :trusted, :unknown, :untrusted, :inappropriate].each do |opt|
  list << "filter_by_status_#{opt}_option"
end

[:all, :collection, :community, :image, :text, :user, :photosynth, :sound, :taxon_concept, :video].each do |type|
  list << "filter_by_type_#{type}_option"
end

[:copy, :move, :remove].each do |act|
  list << "items_no_#{act}_none_selected_warning"
  [:items, :taxa, :articles, :videos, :images, :sounds, :communities, :people, :collections].each do |type|
    list << "#{act}_all_#{type}_button"
  end
end

[:children, :curation, :name, :parents, :preferred, :relationship, :sources, :status].each do |header|
  list << "names_#{header}_column_header"
end

# IGNORE THESE (unusual because the key name is set by a variable):
@bad_keys = ["efault_alt_text", "18n", "change_rating_to_", "your_current_rating_", "sort_by_", "license_",
  "filter_by_status_", "download_", "items_no_", "remove_all_", "move_all_", "copy_all_", "associated_with_",
  "view_", "filter_by_type_", "names_"]

en_master = create_initial_file('en', list)
create_initial_file('ar', list, en_master)
create_initial_file('qqq', list, "DONT")

