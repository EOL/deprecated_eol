class EolStatistic < ActiveRecord::Base

  def self.report_attributes
    {'overall'         => [:members_count, :communities_count, :collections_count, :pages_count, :pages_with_content, :pages_with_text, :pages_with_image, :pages_with_map, :pages_with_video, :pages_with_sound, :pages_without_text, :pages_without_image, :pages_with_image_no_text, :pages_with_text_no_image, :base_pages, :pages_with_at_least_a_trusted_object, :pages_with_at_least_a_curatorial_action, :pages_with_BHL_links, :pages_with_BHL_links_no_text, :pages_with_BHL_links_only, :created_at],
     'content_partner' => [:content_partners, :content_partners_with_published_resources, :content_partners_with_published_trusted_resources, :published_resources, :published_trusted_resources, :published_unreviewed_resources, :newly_published_resources_in_the_last_30_days, :created_at],
     'page_richness'   => [:pages_count, :pages_with_content, :rich_pages, :hotlist_pages, :rich_hotlist_pages, :redhotlist_pages, :rich_redhotlist_pages, :pages_with_score_10_to_39, :pages_with_score_less_than_10, :created_at],
     'curator'         => [:curators, :curators_assistant, :curators_full, :curators_master, :active_curators, :pages_curated_by_active_curators, :objects_curated_in_the_last_30_days, :curator_actions_in_the_last_30_days, :created_at],
     'lifedesk'        => [:lifedesk_taxa, :lifedesk_data_objects, :created_at],
     'marine'          => [:marine_pages, :marine_pages_in_col, :marine_pages_with_objects, :marine_pages_with_objects_vetted, :created_at],
     'user_added_data' => [:data_objects_texts, :udo_published, :udo_published_by_curators, :udo_published_by_non_curators, :created_at],
     'data_object'     => [:data_objects, :data_objects_texts, :data_objects_images, :data_objects_videos, :data_objects_sounds, :data_objects_maps, :data_objects_trusted, :data_objects_unreviewed, :data_objects_untrusted, :data_objects_trusted_or_unreviewed_but_hidden, :created_at]
    }
  end

  def self.overall
    EolStatistic.all(:select => report_attributes['overall'].join(', '), :order => 'created_at desc')
  end

  def self.content_partners
    EolStatistic.all(:select => report_attributes['content_partner'].join(', '), :order => 'created_at desc')
  end

  def self.page_richness
    EolStatistic.all(:select => report_attributes['page_richness'].join(', '), :order => 'created_at desc')
  end

  def self.curators
    EolStatistic.all(:select => report_attributes['curator'].join(', '), :order => 'created_at desc')
  end

  def self.lifedesks
    EolStatistic.all(:select => report_attributes['lifedesk'].join(', '), :order => 'created_at desc')
  end

  def self.marine
    EolStatistic.all(:select => report_attributes['marine'].join(', '), :order => 'created_at desc')
  end

  def self.data_objects
    EolStatistic.all(:select => report_attributes['data_object'].join(', '), :order => 'created_at desc')
  end

  def self.user_added_data
    EolStatistic.all(:select => report_attributes['user_added_data'].join(', '), :order => 'created_at desc')
  end

end
