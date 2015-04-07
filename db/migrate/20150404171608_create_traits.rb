class CreateTraits < ActiveRecord::Migration
  def change
    create_table :traits do |t|
      t.string :traitbank_uri
      t.string :value_literal
      t.integer :associated_to_id # Node
      t.integer :added_by_user_id
      # All of these ids actually point to known_uris:
      t.integer :predicate_id, null: false
      t.integer :value_uri_id
      t.integer :inverse_id
      t.integer :sex_id
      t.integer :lifestage_id
      t.integer :stat_method_id
      t.integer :units_id
    end
    # Build traits from a Sparql query:
    add_index :traits, :traitbank_uri
    # All of the traits for a given attribute:
    add_index :traits, :predicate_id
  end
end
