class CreateNewsItems < ActiveRecord::Migration
  def self.up
    create_table :news_items do |t|
      t.integer :language_id
      t.string :title
      t.text :abstract, :limit => 500
      t.text :description
      t.date :display_date
      t.date :activated_on
      t.boolean :active
      t.text :redirect_url
      t.timestamps
    end
  end

  def self.down
    drop_table :news_items
  end
end
