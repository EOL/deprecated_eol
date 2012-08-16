class AddIndexToEolStatistics < ActiveRecord::Migration
  def self.up
    add_index :eol_statistics, :created_at, :name => 'created_at'
  end

  def self.down
    remove_index :eol_statistics, :created_at
  end
end
