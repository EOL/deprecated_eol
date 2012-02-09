class CreateEolStatistics < ActiveRecord::Migration
  def self.up
    create_table :eol_statistics do |t|
      t.integer :members_count, :limit => 3
      t.integer :communities_count, :limit => 3
      t.integer :collections_count, :limit => 3 
      t.integer :pages_count 
      t.integer :pages_with_content 
      t.integer :pages_with_text 
      t.integer :pages_with_image 
      t.integer :pages_with_map, :limit => 3 
      t.integer :pages_with_video, :limit => 3 
      t.integer :pages_with_sound, :limit => 3 
      t.integer :pages_without_text, :limit => 3 
      t.integer :pages_without_image, :limit => 3 
      t.integer :pages_with_image_no_text, :limit => 3 
      t.integer :pages_with_text_no_image, :limit => 3 
      t.integer :base_pages 
      t.integer :pages_with_at_least_a_trusted_object 
      t.integer :pages_with_at_least_a_curatorial_action, :limit => 3 
      t.integer :pages_with_BHL_links, :limit => 3 
      t.integer :pages_with_BHL_links_no_text, :limit => 3 
      t.integer :pages_with_BHL_links_only, :limit => 3 
      t.integer :content_partners, :limit => 3 
      t.integer :content_partners_with_published_resources, :limit => 3 
      t.integer :content_partners_with_published_trusted_resources, :limit => 3 
      t.integer :published_resources, :limit => 3 
      t.integer :published_trusted_resources, :limit => 3 
      t.integer :published_unreviewed_resources, :limit => 3 
      t.integer :newly_published_resources_in_the_last_30_days, :limit => 3 
      t.integer :data_objects 
      t.integer :data_objects_texts 
      t.integer :data_objects_images 
      t.integer :data_objects_videos, :limit => 3 
      t.integer :data_objects_sounds, :limit => 3 
      t.integer :data_objects_maps, :limit => 3 
      t.integer :data_objects_trusted 
      t.integer :data_objects_unreviewed 
      t.integer :data_objects_untrusted, :limit => 3 
      t.integer :data_objects_trusted_or_unreviewed_but_hidden, :limit => 3 
      t.integer :udo_published, :limit => 3 
      t.integer :udo_published_by_curators, :limit => 3 
      t.integer :udo_published_by_non_curators, :limit => 3 
      t.integer :rich_pages, :limit => 3 
      t.integer :hotlist_pages, :limit => 3 
      t.integer :rich_hotlist_pages, :limit => 3 
      t.integer :redhotlist_pages, :limit => 3 
      t.integer :rich_redhotlist_pages, :limit => 3 
      t.integer :pages_with_score_10_to_39, :limit => 3 
      t.integer :pages_with_score_less_than_10, :limit => 3 
      t.integer :curators, :limit => 3 
      t.integer :curators_assistant, :limit => 3 
      t.integer :curators_full, :limit => 3 
      t.integer :curators_master, :limit => 3 
      t.integer :active_curators, :limit => 3 
      t.integer :pages_curated_by_active_curators, :limit => 3 
      t.integer :objects_curated_in_the_last_30_days, :limit => 3 
      t.integer :curator_actions_in_the_last_30_days, :limit => 3 
      t.integer :lifedesk_taxa, :limit => 3 
      t.integer :lifedesk_data_objects, :limit => 3 
      t.integer :marine_pages, :limit => 3 
      t.integer :marine_pages_in_col, :limit => 3 
      t.integer :marine_pages_with_objects, :limit => 3 
      t.integer :marine_pages_with_objects_vetted, :limit => 3 
      t.datetime :created_at, :null => false, :default => Time.now
    end
  end

  def self.down
    drop_table :eol_statistics
  end
end


