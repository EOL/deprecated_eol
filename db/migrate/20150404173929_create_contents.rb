class CreateContents < ActiveRecord::Migration
  def change
    create_table :contents do |t|
      t.integer :node_id, null: false # Actually a hierarchy_entry _right now_
      t.integer :item_id, null: false
      t.string :item_type, null: false
      # "exemplar"
      t.boolean :overview_include, default: false
      # We only do this on traits... for now... but it's handy to keep from
      # "hiding" it entirely, but making sure it doesn't show up on the
      # overview:
      t.boolean :overview_exclude, default: false
      # We don't ACTUALLY need this for traits ... yet... but I want to add it:
      t.boolean :ancestor, default: false
      # Curation/filters:
      t.boolean :visible, default: true
      t.boolean :vetted, default: false # Meaning, a curator said "yup, this is correct."
    end
    # (I am not including ancestor in indexes, though that will be a common
    # addition--indexing a boolean is thought to barely add performance.)
    #
    # Of course, you want to look up all of a node's contents:
    add_index :contents, :node_id
    # And more often then not, you only want a particular type:
    add_index :contents, [:node_id, :item_type], name: "from_node_by_type"
    # But we also need to know which nodes are related to this item
    #
    add_index :contents, [:item_id, :item_type], name: "from_item"
  end
end
