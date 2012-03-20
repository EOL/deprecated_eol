class AddRequestedCuratorAtToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :requested_curator_at, :timestamp, :after => :requested_curator_level_id
    # Update the requested_curator_at with updated_at for the existing users who applied for curatorship
    # so that, the users who created their accounts months/years ago and recently applied for curatorship
    # can be easily discoverable in the list of curators(which is sorted by requested_curator_at) in admin section.
    execute "UPDATE users SET requested_curator_at=updated_at WHERE requested_curator_level_id IS NOT NULL"
  end

  def self.down
    remove_column :users, :requested_curator_at
  end
end
