class ModifyCuratorApprovedStatusForSomeCurators < ActiveRecord::Migration
  def self.up
    execute "UPDATE users SET curator_approved=1 WHERE curator_level_id > 0"
  end

  def self.down
    # irreversible migration
  end
end
