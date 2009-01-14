class AddAbilityToVerifyEmailAddressForUsers < ActiveRecord::Migration
 
  def self.up
    change_table :users do |t|
      t.string :validation_code, :null => true, :default => '' 
      t.integer :failed_login_attempts, :null => true, :default => 0
    end
  end

  def self.down
     remove_column :users,:validation_code
     remove_column :users,:failed_login_attempts     
  end
  
end
