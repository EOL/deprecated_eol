class CreateDetailsContentTable < ActiveRecord::Migration
  def self.up
    ContentTable.create_details
  end

  def self.down
  end
end
