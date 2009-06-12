class LoadChangeableObjectType < ActiveRecord::Migration
  def self.up
    execute('INSERT INTO changeable_object_types (id, ch_object_type, created_at, updated_at) VALUES (1, "data_object", NOW(), NOW());')
    execute('INSERT INTO changeable_object_types (id, ch_object_type, created_at, updated_at) VALUES (2, "comment", NOW(), NOW());')
    execute('INSERT INTO changeable_object_types (id, ch_object_type, created_at, updated_at) VALUES (3, "tag", NOW(), NOW());')
    execute('INSERT INTO changeable_object_types (id, ch_object_type, created_at, updated_at) VALUES (4, "users_submitted_text", NOW(), NOW());')
  end

  def self.down
    execute('TRUNCATE TABLE changeable_object_types;') 
  end
end
