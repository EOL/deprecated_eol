class AddTaxonColumnToContacts < ActiveRecord::Migration
  def self.up
    add_column :contacts, :taxon_group, :string 
  end

  def self.down
    remove_column :contacts, :taxon_group 
  end
end
