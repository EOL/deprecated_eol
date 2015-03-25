class AddLicenseToImages < ActiveRecord::Migration
  def change
    add_column :images, :license, :string
    add_column :images, :rights, :string
    add_column :images, :rights_holder, :string
    add_column :images, :ratings_1, :integer
    add_column :images, :ratings_2, :integer
    add_column :images, :ratings_3, :integer
    add_column :images, :ratings_4, :integer
    add_column :images, :ratings_5, :integer
    add_column :images, :rating_weighted_average,
      :decimal, precision: 3, scale: 2
  end
end
