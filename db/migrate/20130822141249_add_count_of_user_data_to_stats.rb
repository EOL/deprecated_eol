class AddCountOfUserDataToStats < ActiveRecord::Migration
  def change
    add_column :eol_statistics, :total_user_added_data, 'integer unsigned'
  end
end
