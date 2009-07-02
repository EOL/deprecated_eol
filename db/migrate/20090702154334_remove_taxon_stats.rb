class RemoveTaxonStats < ActiveRecord::Migration
  # this table is no longer neeed in the main Rails database since it is has been replacd with three new tables in the data database
  def self.up
   drop_table :taxon_stats
  end

  def self.down
    create_table :taxon_stats do |t|
      t.string :taxa
      t.string :text
      t.string :image
      t.string :text_and_image
      t.string :bhl_no_text
      t.string :link_no_text
      t.string :image_no_text
      t.string :text_no_image
      t.string :text_or_image
      t.string :text_or_child_image
      t.timestamps
    end    
  end
end
