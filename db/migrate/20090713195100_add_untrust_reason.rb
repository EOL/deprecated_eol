class AddUntrustReason < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    create_table :untrust_reasons do |t|
      t.string :label
      t.timestamps
    end

    execute('INSERT INTO untrust_reasons (id, label, created_at, updated_at) VALUES (1, "Misidentified", NOW(), NOW());')
    execute('INSERT INTO untrust_reasons (id, label, created_at, updated_at) VALUES (2, "Incorrect", NOW(), NOW());')
    execute('INSERT INTO untrust_reasons (id, label, created_at, updated_at) VALUES (3, "Poor", NOW(), NOW());')
    execute('INSERT INTO untrust_reasons (id, label, created_at, updated_at) VALUES (4, "Duplicate", NOW(), NOW());')
    execute('INSERT INTO untrust_reasons (id, label, created_at, updated_at) VALUES (5, "Other", NOW(), NOW());')

    create_table :data_objects_untrust_reasons do |t|
      t.integer :data_object_id
      t.integer :untrust_reason_id
    end
  end

  def self.down
    drop_table :untrust_reasons
    drop_table :data_objects_untrust_reasons
  end
end
