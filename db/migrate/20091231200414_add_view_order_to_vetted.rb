class AddViewOrderToVetted < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute "alter table vetted add view_order tinyint not null"
    if v = Vetted.find_by_label('Trusted')
      v.view_order = 1
      v.save
    end
    if v = Vetted.find_by_label('Unknown')
      v.view_order = 2
      v.save
    end
    if v = Vetted.find_by_label('Untrusted')
      v.view_order = 3
      v.save
    end
    
  end
  
  def self.down
    remove_column :vetted, :view_order
  end
end
