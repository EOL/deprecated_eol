class AlterUsersForAccountRecovery < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE users"\
            " CHANGE password_reset_token recover_account_token CHAR(40),"\
            " CHANGE password_reset_token_expires_at recover_account_token_expires_at DATETIME"
  end

  def self.down
     execute "ALTER TABLE users"\
            " CHANGE recover_account_token password_reset_token CHAR(40),"\
            " CHANGE recover_account_token_expires_at password_reset_token_expires_at DATETIME"
  end
end
