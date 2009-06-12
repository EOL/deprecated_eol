class CreateChangeableObjectTypes < ActiveRecord::Migration

  def self.up
    create_table :changeable_object_types do |t|
      t.string :ch_object_type,  
               :comment => 'Different types have different models and allow different action (DataObject, Comment, Tag, ...)'
      t.timestamps
    end
  end

  def self.down
    drop_table :changeable_object_types
  end

end
