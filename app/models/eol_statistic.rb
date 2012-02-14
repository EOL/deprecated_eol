class EolStatistic < SpeciesSchemaModel
  belongs_to :taxon_concept

  def self.overall
    EolStatistic.all(:select => 'members_count, communities_count, collections_count, pages_count, pages_with_content,
     pages_with_text, pages_with_image,
     pages_with_map, pages_with_video,
     pages_with_sound, pages_without_text,
     pages_without_image, pages_with_image_no_text,
     pages_with_text_no_image, base_pages,
     pages_with_at_least_a_trusted_object,
     pages_with_at_least_a_curatorial_action,
     pages_with_BHL_links, pages_with_BHL_links_no_text,
     pages_with_BHL_links_only, created_at', :order => 'created_at desc')
  end

  def self.content_partners
   EolStatistic.all(:select => 'content_partners, content_partners_with_published_resources, content_partners_with_published_trusted_resources,
    published_resources, published_trusted_resources, published_unreviewed_resources, newly_published_resources_in_the_last_30_days, created_at', :order => 'created_at desc')
  end
     
  def self.rich_pages
   EolStatistic.all(:select => 'pages_count, pages_with_content, rich_pages, hotlist_pages, rich_hotlist_pages, redhotlist_pages, rich_redhotlist_pages,
    pages_with_score_10_to_39, pages_with_score_less_than_10, created_at', :order => 'created_at desc')
  end
     
  def self.curators
    EolStatistic.all(:select => 'curators, curators_assistant, curators_full, curators_master, active_curators,
     pages_curated_by_active_curators, objects_curated_in_the_last_30_days, curator_actions_in_the_last_30_days, created_at', :order => 'created_at desc')
  end

  def self.lifedesks
    EolStatistic.all(:select => 'lifedesk_taxa, lifedesk_data_objects, created_at', :order => 'created_at desc')
  end

  def self.marine_stats
    EolStatistic.all(:select => 'marine_pages, marine_pages_in_col, marine_pages_with_objects, marine_pages_with_objects_vetted, created_at', :order => 'created_at desc')
  end

  def user_submitted_texts
    EolStatistic.all(:select => 'udo_published, udo_published_by_curators, udo_published_by_non_curators, created_at', :order => 'created_at desc')
  end

  def self.data_objects
    EolStatistic.all(:select => 'data_objects,
      data_objects_texts,
      data_objects_images,
      data_objects_videos,
      data_objects_sounds,
      data_objects_maps,
      data_objects_trusted,
      data_objects_unreviewed,
      data_objects_untrusted,
      data_objects_trusted_or_unreviewed_but_hidden,
      udo_published,
      udo_published_by_curators,
      udo_published_by_non_curators,
      created_at', :order => 'created_at desc')
  end

  def self.user_added_texts
    EolStatistic.all(:select => 'data_objects,
      data_objects_texts,
      udo_published,
      udo_published_by_curators,
      udo_published_by_non_curators,
      created_at', :order => 'created_at desc')
  end

end
