class AddDefaultViewToCollections < ActiveRecord::Migration
  def self.up
    create_table :view_styles do |t|
      # Just an ID same as sort_styles.
    end
    create_table :translated_view_styles do |t|
      t.string :name, :limit => 32
      t.references :language, :null => false
      t.references :view_style, :null => false
    end
    add_column :collections, :view_style_id, :integer, :null => true
    ViewStyle.create_defaults if Language.english
  end

  def self.down
    remove_column :collections, :view_style_id
    drop_table :translated_view_styles
    drop_table :view_styles
  end
end
