class AddPolymorphicReplyToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :reply_to_type, :string, :limit => 32
    add_column :comments, :reply_to_id, :integer
  end

  def self.down
    remove_column :comments, :reply_to_id
    remove_column :comments, :reply_to_type
  end
end
