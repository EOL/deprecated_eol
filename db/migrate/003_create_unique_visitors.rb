class CreateUniqueVisitors < ActiveRecord::Migration
  def self.up
    create_table :unique_visitors do |t|
      t.column :count, :integer
      t.timestamps 
    end
    UniqueVisitor.create(:count=>0)
  end

  def self.down
    drop_table :unique_visitors
  end
end
