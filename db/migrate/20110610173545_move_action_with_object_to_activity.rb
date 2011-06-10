class MoveActionWithObjectToActivity < ActiveRecord::Migration
  def self.up
    trans_res = ActiveRecord::Base.connection.execute('select * from translated_action_with_objects').all_hashes
    # Build a fake result set, id => name hash:
    actions = {}
    trans_res.each do |res|
      actions[res["action_with_object_id"].to_i] = {:name => res["action_code"]}
    end
    # First, create (or find) entries in activities for each of the existing ActionWithObject entries.
    actions.keys.each do |id|
      actions[id][:activity] = Activity.find_or_create(actions[id][:name])
    end
    # Now update the curator_activity_logs to use the new ids where the old ones were before
    add_column :curator_activity_logs, :activity_id, :integer
    actions.keys.each do |id|
      CuratorActivityLog.connection.execute(ActiveRecord::Base.sanitize_sql_array([
        "UPDATE curator_activity_logs SET activity_id = ? WHERE action_with_object_id = ?",
        actions[id][:activity].id, id ]))
    end
    remove_column :curator_activity_logs, :action_with_object_id
    drop_table :translated_action_with_objects
    drop_table :action_with_objects
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration.new("We moved the action_with_object_ids to activity_ids, and we're not sure which activities need to become ActionWithObjects, so... sorry.")
  end
end
