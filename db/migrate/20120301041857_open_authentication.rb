class OpenAuthentication < ActiveRecord::Migration
  def self.up
    create_table :open_authentications do |t|
      t.integer    :user_id, :null => false
      t.string     :provider, :null => false
      t.string     :guid, :null => false
      t.string     :token
      t.string     :secret
      t.datetime   :verified_at
      t.timestamps
    end
    execute("CREATE UNIQUE INDEX provider_guid ON open_authentications (provider, guid)")
    execute("CREATE UNIQUE INDEX user_id_provider ON open_authentications (user_id, provider)")
  end

  def self.down
    drop_table :open_authentications
  end
end
