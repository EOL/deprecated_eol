class AddDefaultTaskStates < ActiveRecord::Migration
  def self.up
    TaskState.create_default
  end

  def self.down
    # Nothing to do, don't care to remove these.
  end
end
