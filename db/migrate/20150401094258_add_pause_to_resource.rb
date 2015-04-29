class AddPauseToResource < ActiveRecord::Migration
  def change
    add_column :resources, :pause, :boolean
  end
end
