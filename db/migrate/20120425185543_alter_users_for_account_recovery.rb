class AlterUsersForAccountRecovery < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE users"\
            " CHANGE password_reset_token recover_account_token CHAR(40),"\
            " CHANGE password_reset_token_expires_at recover_account_token_expires_at DATETIME,"\
            " DROP INDEX index_users_on_password_reset_token"\
  end

  def self.down
     execute "ALTER TABLE users"\
            " CHANGE recover_account_token password_reset_token CHAR(40),"\
            " CHANGE recover_account_token_expires_at password_reset_token_expires_at DATETIME,"\
            " ADD UNIQUE KEY index_users_on_password_reset_token (password_reset_token)"
  end
end
