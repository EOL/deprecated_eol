class AddCuratorialToComments < ActiveRecord::Migration

  def self.up
     add_column :comments, :from_curator, :boolean, :default => nil, :null => false    
  end

  def self.down
        remove_column :comments, :from_curator
  end
end
