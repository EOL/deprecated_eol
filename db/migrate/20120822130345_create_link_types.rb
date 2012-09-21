class CreateLinkTypes < ActiveRecord::Migration
  def self.up
    create_table :link_types do |t|
      t.timestamps
    end
    create_table :translated_link_types do |t|
      t.integer :link_type_id, :null => false
      t.integer :language_id, :null => false
      t.string :label, :null => false
      t.string :phonetic_label
    end
    add_index :translated_link_types, [:link_type_id, :language_id], :name => 'link_type_id', :unique => true
    # add_column :data_objects, :link_type_id, :integer, :after => :data_subtype_id
    ['Blog', 'News', 'Organization', 'Paper', 'Multimedia'].each do |link_label|
      lt = LinkType.create!
      TranslatedLinkType.create!(:link_type_id => lt.id, :language_id => Language.default.id, :label => link_label)
    end
  end

  def self.down
    # remove_column :data_objects, :link_type_id
    drop_table :link_types
    drop_table :translated_link_types
  end
end