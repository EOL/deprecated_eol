class DropLastCuratedDate < ActiveRecord::Migration
  def self.up
    drop_table :last_curated_dates
  end

  def self.down
    raise ActiveRecord::IrreversibleMigrationError.new("Unrecoverable last_curated_dates table")
  end
end
