class UserCurator < ActiveRecord::Migration
  
  def self.up
    add_column(:users, :curator_hierarchy_entry_id, :integer, :null => true, :comment => 'Foreign key of a clade the user wishes to be approved to moderate. Presence of this field does not mean the have actually been approved.')
    add_column(:users, :curator_approved, :boolean, :null => false, :default => false, :comment => 'Whether or not the user has been approved to moderate the given item.')
    add_column(:users, :curator_verdict_by_id, :integer, :null => true, :default => nil, :comment => 'The administrator who approved/denied the curation request.')
    add_column(:users, :curator_verdict_at, :datetime, :null => true, :default => nil, :comment => 'When (if ever) the users curation request is decided upon.')
  end
  
  def self.down
    remove_column(:users, :curator_hierarchy_entry_id)
    remove_column(:users, :curator_approved)
    remove_column(:users, :curator_verdict_by_id)
    remove_column(:users, :curator_verdict_at)
  end
  
end
