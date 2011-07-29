class AddUserIdentities < ActiveRecord::Migration
  def self.up
    execute("CREATE TABLE `user_identities` (
      `id` smallint NOT NULL auto_increment,
      `sort_order` tinyint unsigned NOT NULL,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    
    execute("CREATE TABLE `translated_user_identities` (
      `id` int NOT NULL auto_increment,
      `user_identity_id` smallint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(255) NOT NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`user_identity_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    
    execute("CREATE TABLE `users_user_identities` (
      `user_id` int unsigned NOT NULL,
      `user_identity_id` smallint unsigned NOT NULL,
      PRIMARY KEY (`user_id`, `user_identity_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    
    UserIdentity.create_defaults
  end

  def self.down
    drop_table :user_identities
    drop_table :translated_user_identities
    drop_table :users_user_identities
  end
end
