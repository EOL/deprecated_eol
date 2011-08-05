class RemoveMemberPrivilegeFromCommunityActLog < EOL::LoggingMigration
  def self.up
    CommunityActivityLog.connection.execute("DELETE FROM community_activity_logs WHERE member_privilege_id IS NOT NULL")
    remove_column :community_activity_logs, :member_privilege_id
  end

  def self.down
    add_column :community_activity_logs, :member_privilege_id, :integer
  end
end
