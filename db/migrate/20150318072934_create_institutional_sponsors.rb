class CreateInstitutionalSponsors < ActiveRecord::Migration
  def change
    create_table :institutional_sponsors do |t|
      t.string :name
      t.string :logo_url
      t.string :url
      t.boolean :active

      t.timestamps
    end
  end
end
