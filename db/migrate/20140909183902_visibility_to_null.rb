class VisibilityToNull < ActiveRecord::Migration
  def up
    change_column_default(:user_added_data, :visibility_id, nil)
  end

  # No down, because the old behavior was evil (default set in code)
end
