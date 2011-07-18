class AddAgreedWithTermsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :agreed_with_terms, :boolean
  end

  def self.down
    remove_column :users, :agreed_with_terms
  end
end
