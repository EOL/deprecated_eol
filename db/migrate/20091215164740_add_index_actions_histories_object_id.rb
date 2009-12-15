class AddIndexActionsHistoriesObjectId < ActiveRecord::Migration
  def self.up
    execute("create index object_id on actions_histories(object_id)")
  end
  
  def self.down
    remove_index :actions_histories, :name => 'object_id'
  end
end
