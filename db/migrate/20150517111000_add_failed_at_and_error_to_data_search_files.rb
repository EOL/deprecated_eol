class AddFailedAtAndErrorToDataSearchFiles < ActiveRecord::Migration
  def change
     add_column :data_search_files, :failed_at, :datetime, :null => true
     add_column :data_search_files, :error, :text, :null => true
  end
end
