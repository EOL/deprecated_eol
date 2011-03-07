class AddDefaultTaskNames < ActiveRecord::Migration
  def self.up
    TaskName.create(:description => 'Review')
    TaskName.create(:description => 'Comment on')
    TaskName.create(:description => 'Curate')
    TaskName.create(:description => 'Merge synonym')
    TaskName.create(:description => 'Split homonym')
    TaskName.create(:description => 'Approve member')
    TaskName.create(:description => 'Approve privilege request')
    TaskName.create(:description => 'Merge taxa list')
  end

  def self.down
    # nothing to do, don't care.
  end
end
