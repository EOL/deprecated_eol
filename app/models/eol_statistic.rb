class EolStatistic < ActiveRecord::Base

  scope :overall, lambda {
    { select: [ :members_count, :communities_count, :collections_count,
                  :pages_count, :pages_with_content, :pages_with_text, :pages_with_image,
                  :pages_with_map, :pages_with_video, :pages_with_sound, :pages_without_text,
                  :pages_without_image, :pages_with_image_no_text, :pages_with_text_no_image,
                  :base_pages, :pages_with_at_least_a_trusted_object, :total_taxa_with_data,
                  :pages_with_at_least_a_curatorial_action, :pages_with_BHL_links,
                  :pages_with_BHL_links_no_text, :pages_with_BHL_links_only, :created_at ].join(', ') } }

  scope :content_partners, lambda {
    { select: [ :content_partners, :content_partners_with_published_resources,
                  :content_partners_with_published_trusted_resources, :published_resources,
                  :published_trusted_resources, :published_unreviewed_resources,
                  :newly_published_resources_in_the_last_30_days, :created_at ].join(', ') } }

  scope :curators, lambda {
    { select: [ :curators, :curators_assistant, :curators_full, :curators_master,
                  :active_curators, :pages_curated_by_active_curators,
                  :objects_curated_in_the_last_30_days,
                  :curator_actions_in_the_last_30_days, :created_at ].join(', ') } }

  scope :data_objects, lambda {
    { select: [ :data_objects, :data_objects_texts, :data_objects_images,
                  :data_objects_videos, :data_objects_sounds, :data_objects_maps,
                  :data_objects_trusted, :data_objects_unreviewed, :data_objects_untrusted,
                  :data_objects_trusted_or_unreviewed_but_hidden, :created_at ].join(', ') } }

  scope :lifedesks, lambda {
    { select: [ :lifedesk_taxa, :lifedesk_data_objects, :created_at ].join(', ') } }

  scope :marine, lambda {
    { select: [ :marine_pages, :marine_pages_in_col, :marine_pages_with_objects,
                  :marine_pages_with_objects_vetted, :created_at ].join(', ') } }

  scope :page_richness, lambda {
    { select: [ :pages_count, :pages_with_content, :rich_pages, :hotlist_pages,
                   :rich_hotlist_pages, :redhotlist_pages, :rich_redhotlist_pages,
                   :pages_with_score_10_to_39, :pages_with_score_less_than_10, :created_at ].join(', ') } }

  scope :users_data_objects, lambda {
    { select: [ :data_objects_texts, :udo_published, :udo_published_by_curators,
                  :udo_published_by_non_curators, :created_at ].join(', ') } }

  scope :data, lambda {
    { select: [ :total_triples, :total_occurrences, :total_measurements, :total_associations,
                  :total_measurement_types, :total_association_types, :total_taxa_with_data,
                  :total_user_added_data, :created_at ].join(', ') } }

  # Retrieves stats for specific dates (i.e. stats reported within the 24 hours from midnight
  # to 23:59:59 of the day represented by each date, in other words not a range of 'from to' dates).
  # Assumes dates is an array of Time, TimeWithZone or Date instances.
  scope :on_dates, lambda {|dates|
    conditions = []
    conditions_replacements = {}
    dates.each_with_index do |date, i|
      conditions << "created_at BETWEEN :from#{i} AND :to#{i}"
      conditions_replacements["from#{i}".to_sym] = date.beginning_of_day
      conditions_replacements["to#{i}".to_sym] = date.end_of_day
    end
    { conditions: [conditions.join(' OR '), conditions_replacements] }
  }

  scope :at_least_one_week_ago, lambda {|limit| { conditions: "created_at < '#{Time.now - 1.week}'", order: 'created_at DESC', limit: limit } }

  scope :latest, lambda {|limit| { order: 'created_at DESC', limit: limit } }

  attr_accessor :greatest

  def rich_hotlist_pages_percentage
    (rich_hotlist_pages.to_f / hotlist_pages.to_f) * 100.0 rescue 0
  end

  def rich_redhotlist_pages_percentage
    (rich_redhotlist_pages.to_f / redhotlist_pages.to_f) * 100.0 rescue 0
  end

  # TODO: Slightly cheating to have these here but we re-use this sorted list of
  # attribute subsets in a number of places. Is there a better way to achieve this?
  def self.sorted_report_attributes(report)
    report = report.to_sym
    case report
    when :overall
      [:members_count, :communities_count, :collections_count, :pages_count,
       :pages_with_content, :pages_with_text, :pages_with_image, :pages_with_map,
       :pages_with_video, :pages_with_sound, :pages_without_text, :pages_without_image,
       :pages_with_image_no_text, :pages_with_text_no_image, :base_pages,
       :pages_with_at_least_a_trusted_object, :pages_with_at_least_a_curatorial_action,
       :pages_with_BHL_links, :pages_with_BHL_links_no_text, :pages_with_BHL_links_only,
       :created_at]
    when :content_partners
      [:content_partners, :content_partners_with_published_resources,
       :content_partners_with_published_trusted_resources, :published_resources,
       :published_trusted_resources, :published_unreviewed_resources,
       :newly_published_resources_in_the_last_30_days, :created_at]
    when :page_richness
       [:pages_count, :pages_with_content, :rich_pages, :hotlist_pages, :rich_hotlist_pages,
        :redhotlist_pages, :rich_redhotlist_pages, :pages_with_score_10_to_39,
        :pages_with_score_less_than_10, :created_at]
    when :curators
      [:curators, :curators_assistant, :curators_full, :curators_master, :active_curators,
       :pages_curated_by_active_curators, :objects_curated_in_the_last_30_days,
       :curator_actions_in_the_last_30_days, :created_at]
    when :lifedesks
      [:lifedesk_taxa, :lifedesk_data_objects, :created_at]
    when :marine
      [:marine_pages, :marine_pages_in_col, :marine_pages_with_objects,
       :marine_pages_with_objects_vetted, :created_at]
    when :users_data_objects
      [:data_objects_texts, :udo_published, :udo_published_by_curators,
       :udo_published_by_non_curators, :created_at]
    when :data_objects
      [:data_objects, :data_objects_texts, :data_objects_images, :data_objects_videos,
       :data_objects_sounds, :data_objects_maps, :data_objects_trusted,
       :data_objects_unreviewed, :data_objects_untrusted, :data_objects_trusted_or_unreviewed_but_hidden, :created_at]
    when :data
      [:total_triples, :total_occurrences, :total_measurements, :total_associations,:total_measurement_types,
       :total_association_types, :total_taxa_with_data,:total_user_added_data, :created_at]
    end
  end

  def total_data_records
    latest_statistics = EolStatistic.find(:last)
    latest_statistics.total_measurements + latest_statistics.total_associations
  end
  
  # Performs greater than comparison on two instances of EolStatistic
  # Saves results to EolStatistic.greatest attribute
  def self.compare_and_set_greatest(eol_statistic_a, eol_statistic_b)
    attribute_names = eol_statistic_a.attribute_names + [ 'rich_hotlist_pages_percentage', 'rich_redhotlist_pages_percentage' ]
    eol_statistic_a.greatest = Hash[attribute_names.collect do |k|
                                 [k.to_sym, eol_statistic_a.send(k) >= eol_statistic_b.send(k)]
                               end]
    eol_statistic_b.greatest = Hash[attribute_names.collect do |k|
                                 [k.to_sym, eol_statistic_b.send(k) >= eol_statistic_a.send(k)]
                               end]
    [eol_statistic_a.greatest, eol_statistic_b.greatest]
  end

end
