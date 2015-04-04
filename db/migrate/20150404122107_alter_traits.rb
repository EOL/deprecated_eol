class AlterTraits < ActiveRecord::Migration
  def up
    if Trait.connection.config[:adapter] == "mysql2"
      # Faster to do them all at once, it's a huge table:
      Trait.connection.execute(
        "ALTER TABLE traits"\
        "  ADD COLUMN overview_include TINYINT(1) NOT NULL DEFAULT 0,"\
        "  ADD COLUMN overview_exclude TINYINT(1) NOT NULL DEFAULT 0"
      )
      # TODO: we want to store known_uri ids ONLY (except the uri, which we use
      # for matching to Virtuoso) on this table; we want to add the sex,
      # lifestage, and stat fields. We want to add the observation ID (why do we
      # lose that?), and we want a NORMALIZED unit known_uri; lets also add an
      # object_taxon_concept_id for associations. BEASTLY!
      Trait.connection.execute(
        "UPDATE traits SET overview_include = 1 WHERE id IN"\
        "  (SELECT data_point_uri_id FROM taxon_data_exemplars"\
        "    WHERE exclude = 0)"
      )
      Trait.connection.execute(
        "UPDATE traits SET overview_exclude = 1 WHERE id IN"\
        "  (SELECT data_point_uri_id FROM taxon_data_exemplars"\
        "    WHERE exclude = 1)"
      )
    else
      add_column(:traits, :overview_include, :boolean, null: false,
        default: false)
      add_column(:traits, :overview_exclude, :boolean, null: false,
        default: false)
      # NOTE: It's nigh impossible that this affects anyone:
      message = "WARNING: I don't know how to populate the traits overview\n"\
        "inclusions and exclusions. You have lost this data. Sorry.\n"
      Logger.error(message)
      puts message
    end
  end

  def down
    create_table :taxon_data_exemplars do |t|
      t.integer :taxon_concept_id, null: false
      t.integer :data_point_uri_id, null: false
      t.boolean :exclude, default: false, null: false
    end
    add_index :taxon_data_exemplars, :taxon_concept_id
    message = "WARNING: I don't know how to populate the taxon_data_exemplars\n"\
      "table. You have lost this data. Sorry.\n"
    remove_column(:traits, :overview_include)
    remove_column(:traits, :overview_exclude)
  end
end
