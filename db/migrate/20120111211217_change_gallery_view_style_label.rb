class ChangeGalleryViewStyleLabel < ActiveRecord::Migration
  def self.up
    execute "UPDATE translated_view_styles SET name='Gallery' WHERE name='Image Gallery'"
  end

  def self.down
    execute "UPDATE translated_view_styles SET name='Image Gallery' WHERE name='Gallery'"
  end
end
