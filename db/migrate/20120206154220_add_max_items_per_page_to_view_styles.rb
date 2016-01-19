class AddMaxItemsPerPageToViewStyles < ActiveRecord::Migration
  def self.up
    add_column :view_styles, :max_items_per_page, :int
    ViewStyle.reset_column_information
    ViewStyle.find_each do |vs|
      if vs.name.downcase == 'annotated'
        vs.max_items_per_page = 50
        vs.save
      elsif vs.name.downcase == 'gallery'
        vs.max_items_per_page = 150
        vs.save
      elsif vs.name.downcase == 'list'
        vs.max_items_per_page = 300
        vs.save
      end
    end
  end

  def self.down
    remove_column :view_styles, :max_items_per_page
  end
end
