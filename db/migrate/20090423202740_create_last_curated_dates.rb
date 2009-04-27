class CreateLastCuratedDates < ActiveRecord::Migration
  def self.up                                                                                                                
    create_table :last_curated_dates do |t|                                                                                  
      t.integer :taxon_concept_id                                                                                                     
      t.integer :user_id                                                                                                     
      t.timestamp :last_curated                                                                                              
    end                                                                                                                      
  end                                                                                                                        

  def self.down                                                                                                              
    drop_table :last_curated_dates                                                                                           
  end                                                                                                                        
end
