class DropVettedAndVisibilityFromDataObjects < ActiveRecord::Migration
  def self.up
    UsersDataObject.connection.execute("
      UPDATE users_data_objects udo, data_objects dato SET udo.vetted_id = dato.vetted_id, udo.visibility_id = dato.visibility_id WHERE udo.data_object_id = dato.id
    ")
    UsersDataObject.connection.execute("
      ALTER TABLE users_data_objects MODIFY vetted_id INT NOT NULL
    ")
    remove_column :data_objects, :visibility_id
    remove_column :data_objects, :vetted_id
  end

  def self.down
    add_column :data_objects, :vetted_id, :integer
    add_column :data_objects, :visibility_id, :integer
  end
end