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
  helpers
  models

  views/layouts/v2

  views/activity_logs
  views/admins
  views/api/docs
  views/collection_items
  views/collections
  views/comments
  views/communities
  views/content
  views/content_partners
  views/data_objects
  views/members
  views/navigation
  views/search
  views/sessions
  views/taxa/communities
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
  views/wikipedia_queues

  controllers/administrator/content_page_controller.rb
  controllers/administrator/content_partner_report_controller.rb
  controllers/administrator/table_of_contents_controller.rb
  controllers/administrator/user_data_object_controller.rb
  controllers/admins/content_pages_controller.rb
  controllers/admins/content_partner_reports_controller.rb
  controllers/admins/content_partners_controller.rb
  controllers/admins/hierarchies_controller.rb
  controllers/admins/monthly_notification_controller.rb
  controllers/admins/translated_content_pages_controller.rb
  controllers/admins_controller.rb
  controllers/admins/content_pages_controller.rb
  controllers/api/docs_controller.rb
  controllers/api_controller.rb
  controllers/application_controller.rb
  controllers/collection_items_controller.rb
  controllers/collections_controller.rb
  controllers/comments_controller.rb
  controllers/communities/collections_controller.rb
  controllers/communities_controller.rb
  controllers/content_controller.rb
  controllers/content_partners/content_partner_agreements_controller.rb
  controllers/content_partners/content_partner_contacts_controller.rb
  controllers/content_partners/resources_controller.rb
  controllers/content_partners/statistics_controller.rb
  controllers/content_partners_controller.rb
  controllers/data_objects_controller.rb
  controllers/fckeditor_controller.rb
  controllers/feeds_controller.rb
  controllers/hierarchy_entries_controller.rb
  controllers/members_controller.rb
  controllers/search_controller.rb
  controllers/sessions_controller.rb
  controllers/taxa/communities_controller.rb
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
  controllers/users/communities_controller.rb
  controllers/users/content_partners_controller.rb
  controllers/users/newsfeeds_controller.rb
  controllers/users_controller.rb
  controllers/wikipedia_queues_controller.rb

  views/admin/_navigation.html.haml
  views/administrator/comment/index.html.haml
  views/administrator/content_partner_report/report_partner_curated_data.haml
  views/administrator/curator/_user_row.html.haml
  views/administrator/hierarchy/index.html.haml
  views/administrator/user/_form.html.haml
  views/administrator/user/index.html.haml
  views/administrator/user_data_object/index.html.haml
  views/content_partner_account/reports/_comments_report.html.haml
  views/content_partner_account/reports/_taxa_comments_report.html.haml
  views/content_partner_account/reports/_user_submitted_text_report.html.haml
  views/layouts/main.html.haml
  views/notifier/account_activated.html.haml
  views/notifier/contact_us_auto_response.html.haml
  views/notifier/curator_approved.html.haml
  views/notifier/curator_unapproved.html.haml
  views/notifier/media_contact_auto_response.html.haml
  views/notifier/monthly_stats.html.haml
  views/notifier/reset_password.html.haml
  views/notifier/user_message.html.haml
  views/notifier/verify_user.html.haml
  views/shared/_add_to_my_collection.html.haml
  views/shared/_flash_messages.html.haml
  views/shared/_google_custom_search_params.html.haml
  views/shared/_hierarchy_citation.html.haml
  views/shared/_item_summary_article.html.haml
  views/shared/_item_summary_collection.html.haml
  views/shared/_item_summary_community.html.haml
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
  views/taxa/_communities_summary.html.haml
  views/taxa/_curator_citation.html.haml
  views/taxa/_curators_summary.html.haml
  views/taxa/_iucn_status_summary.html.haml
  views/taxa/_media_summary.html.haml
  views/taxa/_overview_image_taxon_link.html.haml
  views/taxa/_recognized_by.html.haml
  views/taxa/_text_summary.html.haml
  views/taxa/content/_content_content_summary.html.haml
].compact.each do |dir|
  list += grepper(dir)
end

# ADD THESE:
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

