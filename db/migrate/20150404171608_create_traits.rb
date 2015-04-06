class CreateTraits < ActiveRecord::Migration
  def change
    create_table :traits do |t|
      t.string :traitbank_uri
      # All of these ids actually point to known_uris:
      t.integer :predicate_id, null: false
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
