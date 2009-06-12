class LoadActionWithObjects < ActiveRecord::Migration
  def self.up
   execute('INSERT INTO action_with_objects (id, action_code, created_at, updated_at) VALUES (1, "create", NOW(), NOW());')
   execute('INSERT INTO action_with_objects (id, action_code, created_at, updated_at) VALUES (2, "update", NOW(), NOW());')
   execute('INSERT INTO action_with_objects (id, action_code, created_at, updated_at) VALUES (3, "delete", NOW(), NOW());')
   execute('INSERT INTO action_with_objects (id, action_code, created_at, updated_at)	VALUES (4, "trusted", NOW(), NOW());')
   execute('INSERT INTO action_with_objects (id, action_code, created_at, updated_at) VALUES (5, "untrusted", NOW(), NOW());')
   execute('INSERT INTO action_with_objects (id, action_code, created_at, updated_at) VALUES (6, "show", NOW(), NOW());')
   execute('INSERT INTO action_with_objects (id, action_code, created_at, updated_at) VALUES (7, "hide", NOW(), NOW());')
   execute('INSERT INTO action_with_objects (id, action_code, created_at, updated_at) VALUES (8, "inappropriate", NOW(), NOW());')
   execute('INSERT INTO action_with_objects (id, action_code, created_at, updated_at) VALUES (9, "rate", NOW(), NOW());')
  end

  def self.down
    execute('TRUNCATE TABLE action_with_objects;') 
  end
end
