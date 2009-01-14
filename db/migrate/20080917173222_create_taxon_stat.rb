class CreateTaxonStat < ActiveRecord::Migration
  def self.up
    create_table :taxon_stats do |t|
       t.string :taxa
       t.string :text
       t.string :image
       t.string :text_and_images
       t.string :bhl_no_text
       t.string :link_no_text
       t.string :link_no_text
       t.string :image_no_text
       t.string :text_no_image
       t.string :text_or_image
       t.string :text_or_child_image                  
       t.timestamps
     end
  end

  def self.down
    drop_table :taxon_stats
  end
end
