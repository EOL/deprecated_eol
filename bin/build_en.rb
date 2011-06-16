#!/usr/local/env ruby

require 'ruby-debug'
require 'set'
require 'yaml'

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
      if master.has_key? k
        puts "** WARNING: No #{lang} key found for '#{k}'.  Faking it."
        new_hash[lang][k] = master[k]
      else
        puts "** WARNING: No #{lang} key found for '#{k}', and no master value either.  Leaving empty..."
        new_hash[lang][k] = "TODO"
      end
    end
  end

  File.open(target, "w") do |f|
    f.write(new_hash.to_yaml)
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
# Home Page, Taxon Page Overview, Collections Interface, Community Interface
%w[
  models

  controllers/application_controller.rb
  controllers/collections_controller.rb
  controllers/communities_controller.rb
  controllers/communities/collections_controller.rb
  controllers/content_controller.rb
  controllers/taxa/overviews_controller.rb
  controllers/taxa/details_controller.rb
  controllers/taxa/media_controller.rb

  views/collection_items/_show.html.haml
  views/collections/_collection_summary.html.haml
  views/collections/_show.html.haml
  views/collections/show.html.haml
  views/communities/collections/index.html.haml
  views/communities/show.html.haml
  views/content/error.html.haml
  views/content/_error.html.haml
  views/content/error.html.haml
  views/content/index.html.haml
  views/data_objects/_attribution_minimal.html.haml
  views/data_objects/_data_object_text.html.haml
  views/data_objects/_license.html.haml
  views/data_objects/_owner.html.haml
  views/data_objects/_rating.html.haml
  views/feed_items/_form.html.haml
  views/feed_items/_index.html.haml
  views/layouts/_footer_menu.html.haml
  views/layouts/main.html.haml
  views/layouts/_search_field.html.haml
  views/layouts/_top_menu_item.html.haml
  views/layouts/v2/application.html.haml
  views/layouts/v2/basic.html.haml
  views/layouts/v2/collections.html.haml
  views/layouts/v2/communities.html.haml
  views/layouts/v2/_global_navigation.html.haml
  views/layouts/v2/_search.html.haml
  views/layouts/v2/taxa.html.haml
  views/layouts/v2/users.html.haml
  views/members/_index.html.haml
  views/roles/_index.html.haml
  views/shared/_flash_messages.html.haml
  views/shared/_google_custom_search_params.html.haml
  views/shared/_join_eol.html.haml
  views/shared/_sort_by_date_form.html.haml
  views/taxa/_classifications_summary.html.haml
  views/taxa/_collections_summary.html.haml
  views/taxa/_communities_summary.html.haml
  views/taxa/content/_content_content_summary.html.haml
  views/taxa/_curators_summary.html.haml
  views/taxa/details/_category_content.html.haml
  views/taxa/details/show.html.haml
  views/taxa/_iucn_status_summary.html.haml
  views/taxa/media/_media_sort_filter.html.haml
  views/taxa/media/show.html.haml
  views/taxa/_media_summary.html.haml
  views/taxa/_media_thumbnail.html.haml
  views/taxa/overviews/show.html.haml
  views/taxa/_show.html.haml
  views/taxa/show.html.haml
  views/taxa/_text_summary.html.haml
  views/users/collections/index.html.haml

].compact.each do |dir|
  list += grepper(dir)
end

# ADD THESE:
list << "video_thumbnail_alt_text"
list << "sound_thumbnail_alt_text"
list << "image_thumbnail_alt_text"
list << "roles"
(1..5).each do |n|
  list << "change_rating_to_#{n}_of_5"
end
(0..5).each do |n|
  list << "your_current_rating_#{n}_of_5"
end
list << "sort_by_label"
list << "sort_by_data_type_option"
list << "sort_by_default_option"
list << "sort_by_newest_option"
list << "sort_by_oldest_option"
list << "sort_by_rating_option"
list << "sort_by_vetted_option"

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

# IGNORE THESE (unusual because the key name is set by a variable):
@bad_keys = ["efault_alt_text", "18n", "change_rating_to_", "your_current_rating_", "sort_by_", "license_"]

en_master = create_initial_file('en', list)

create_initial_file('ar', list, en_master)

