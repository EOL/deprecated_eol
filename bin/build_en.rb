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
# Home Page, Taxon Page Overview, Collections Interface, Community Interface
%w[
  models

  views/layouts/v2

  views/data_objects
  views/collection_items
  views/collections
  views/search

  controllers/account_controller.rb
  controllers/application_controller.rb
  controllers/collection_items_controller.rb
  controllers/collections_controller.rb
  controllers/content_controller.rb
  controllers/data_objects_controller.rb
  controllers/search_controller.rb
  controllers/taxa_controller.rb
  controllers/taxa/details_controller.rb
  controllers/taxa/maps_controller.rb
  controllers/taxa/media_controller.rb
  controllers/taxa/names_controller.rb
  controllers/taxa/overviews_controller.rb
  controllers/users/collections_controller.rb
  controllers/users_controller.rb
  controllers/users/newsfeeds_controller.rb

  views/account/login.html.haml
  views/account/signup.html.haml
  views/activity_logs/_collection_activity_log.html.haml
  views/activity_logs/_comment.html.haml
  views/activity_logs/_index.html.haml
  views/comments/_new.html.haml
  views/content/_error.html.haml
  views/content/error.html.haml
  views/content/index.html.haml
  views/content/_march_of_life_item.html.haml
  views/curator_account/_curator_form.html.haml
  views/shared/_add_to_my_collection.html.haml
  views/shared/_flash_messages.html.haml
  views/shared/_google_custom_search_params.html.haml
  views/shared/_item_summary_collection.html.haml
  views/shared/_item_summary_taxon.html.haml
  views/shared/_join_eol.html.haml
  views/shared/_sort_by_date_form.html.haml
  views/taxa/_classifications_summary.html.haml
  views/taxa/_collections_summary.html.haml
  views/taxa/_communities_summary.html.haml
  views/taxa/content/_content_content_summary.html.haml
  views/taxa/_curators_summary.html.haml
  views/taxa/details/_category_content.html.haml
  views/taxa/details/index.html.haml
  views/taxa/_iucn_status_summary.html.haml
  views/taxa/maps/_maps.html.haml
  views/taxa/maps/show.html.haml
  views/taxa/media/index.html.haml
  views/taxa/media/_media_sort_filter.html.haml
  views/taxa/_media_summary.html.haml
  views/taxa/_media_thumbnail.html.haml
  views/taxa/names/_common_names.html.haml
  views/taxa/names/common_names.html.haml
  views/taxa/names/_filter_by_name_category.html.haml
  views/taxa/names/show.html.haml
  views/taxa/names/synonyms.html.haml
  views/taxa/overviews/show.html.haml
  views/taxa/_recognised_by.html.haml
  views/taxa/_text_summary.html.haml
  views/users/collections/index.html.haml
  views/users/newsfeeds/show.html.haml

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

