class CreateUserInfos < ActiveRecord::Migration
  def self.up
    create_table :user_infos do |t|
      t.reference :user
      t.string :areas_of_interest
      t.string :heard_of_eol, :limit => 128
      t.boolean :interested_in_contributing
      t.boolean :interested_in_curating
      t.boolean :interested_in_advisory_forum
      t.boolean :show_information
      t.string :age_range, :limit => 16
      t.timestamps
    end
  end

  def self.down
    drop_table :user_infos
  end
end
