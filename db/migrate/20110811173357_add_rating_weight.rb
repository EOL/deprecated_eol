class AddRatingWeight < ActiveRecord::Migration
  def self.up
    add_column :curator_levels, :rating_weight, :integer, :default => 1
    add_column :users_data_objects_ratings, :weight, :integer, :default => 1
    if CuratorLevel.master
      CuratorLevel.connection.execute( "UPDATE curator_levels SET rating_weight = 5 WHERE id = #{CuratorLevel.master.id}")
    end
    if CuratorLevel.full
      CuratorLevel.connection.execute( "UPDATE curator_levels SET rating_weight = 3 WHERE id = #{CuratorLevel.full.id}")
    end
    if CuratorLevel.assistant
      CuratorLevel.connection.execute( "UPDATE curator_levels SET rating_weight = 2 WHERE id = #{CuratorLevel.assistant.id}")
    end
  end

  def self.down
    remove_column :users_data_objects_rating, :weight
    remove_column :curator_levels, :rating_weight
  end
end
