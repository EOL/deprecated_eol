class EolStatistic < ActiveRecord::Base


  named_scope :overall, lambda {
    { :select => [:members_count, :communities_count, :collections_count,
                  :pages_count, :pages_with_content, :pages_with_text,
                  :pages_with_image, :pages_with_map, :pages_with_video,
                  :pages_with_sound, :pages_without_text, :pages_without_image,
                  :pages_with_image_no_text, :pages_with_text_no_image, :base_pages,
                  :pages_with_at_least_a_trusted_object, :pages_with_at_least_a_curatorial_action,
                  :pages_with_BHL_links, :pages_with_BHL_links_no_text,
                  :pages_with_BHL_links_only, :created_at].join(', ') } }

  named_scope :content_partners, lambda {
    { :select => [:content_partners, :content_partners_with_published_resources,
                  :content_partners_with_published_trusted_resources, :published_resources,
                  :published_trusted_resources, :published_unreviewed_resources,
                  :newly_published_resources_in_the_last_30_days, :created_at].join(', ') } }

  named_scope :curators, lambda {
    { :select => [:curators, :curators_assistant, :curators_full, :curators_master,
                  :active_curators, :pages_curated_by_active_curators,
                  :objects_curated_in_the_last_30_days,
                  :curator_actions_in_the_last_30_days, :created_at].join(', ') } }

  named_scope :data_objects, lambda {
    { :select => [:data_objects, :data_objects_texts, :data_objects_images,
                  :data_objects_videos, :data_objects_sounds, :data_objects_maps,
                  :data_objects_trusted, :data_objects_unreviewed, :data_objects_untrusted,
                  :data_objects_trusted_or_unreviewed_but_hidden, :created_at].join(', ') } }

  named_scope :lifedesks, lambda {
    { :select => [:lifedesk_taxa, :lifedesk_data_objects, :created_at].join(', ') } }

  named_scope :marine, lambda {
    { :select => [:marine_pages, :marine_pages_in_col, :marine_pages_with_objects,
                  :marine_pages_with_objects_vetted, :created_at].join(', ') } }

  named_scope :page_richness, lambda {
    { :select  => [:pages_count, :pages_with_content, :rich_pages, :hotlist_pages,
                   :rich_hotlist_pages, :redhotlist_pages, :rich_redhotlist_pages,
                   :pages_with_score_10_to_39, :pages_with_score_less_than_10, :created_at].join(', ') } }

  named_scope :users_data_objects, lambda {
    { :select => [:data_objects_texts, :udo_published, :udo_published_by_curators,
                  :udo_published_by_non_curators, :created_at].join(', ') } }

  # Retrieves stats for specific dates (i.e. stats reported within the 24 hours from midnight
  # to 23:59:59 of the day represented by each date, in other words not a range of 'from to' dates).
  # Assumes dates is an array of Time, TimeWithZone or Date instances.
  named_scope :on_dates, lambda {|dates|
    conditions = []
    conditions_replacements = {}
    dates.each_with_index do |date, i|
      conditions << "created_at BETWEEN :from#{i} AND :to#{i}"
      conditions_replacements["from#{i}".to_sym] = date.beginning_of_day
      conditions_replacements["to#{i}".to_sym] = date.end_of_day
    end
    { :conditions => [conditions.join(' OR '), conditions_replacements] }
  }

  named_scope :earliest, lambda { { :order => 'created_at ASC', :limit => 1 } }

  named_scope :latest, lambda { { :order => 'created_at DESC', :limit => 1 } }

  attr_accessor :greatest

  # Performs greater than comparison on two instances of EolStatistic
  # Saves results to EolStatistic.greatest attribute
  def self.compare_and_set_greatest(eol_statistic_a, eol_statistic_b)
    eol_statistic_a.greatest = Hash[eol_statistic_a.attributes.collect do |k,v|
                                 [k.to_sym, v > eol_statistic_b.send(k)]
                               end]
    eol_statistic_b.greatest = Hash[eol_statistic_a.greatest.collect{|k,v| [k,!v]}]
    [eol_statistic_a.greatest, eol_statistic_b.greatest]
  end

end
