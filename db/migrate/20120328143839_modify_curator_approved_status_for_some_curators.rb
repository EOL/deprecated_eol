class ModifyCuratorApprovedStatusForSomeCurators < ActiveRecord::Migration
  def self.up
    # Note: here we are updating only full and master curators who were missing curator_approved flag as true.
    full_and_master_curators = [ CuratorLevel.full.id, CuratorLevel.master.id ] rescue nil
    execute "UPDATE users SET curator_approved=1 WHERE curator_level_id IN (#{ full_and_master_curators.join(',') })" if full_and_master_curators
  end

  def self.down
    # irreversible migration
  end
end
