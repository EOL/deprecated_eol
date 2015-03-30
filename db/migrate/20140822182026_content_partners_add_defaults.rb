class ContentPartnersAddDefaults < ActiveRecord::Migration
  def up
    change_column(:content_partners, :string, :notes, limit: 6000, default: "",
      null: true)
    change_column(:content_partners, :string, :description_of_data,
      limit: 6000, default: "", null: true)
    change_column(:content_partners, :string, :description, limit: 6000,
      default: "", null: true)
    change_column(:content_partners, :string, :full_name, default: "",
      null: true)
  end

  def down
    # Nevermind, I don't care.
  end
end
