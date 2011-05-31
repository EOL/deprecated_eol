class CreateContentTables < ActiveRecord::Migration
  def self.up
    create_table :content_tables do |t|
      t.timestamps
    end
  end

  def self.down
    drop_table :content_tables
  end
end
