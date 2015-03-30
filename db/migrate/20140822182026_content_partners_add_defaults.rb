class ContentPartnersAddDefaults < ActiveRecord::Migration
  def up
    # TODO: This may not work; you may have to lower these 6000s to 5000s.
    change_column(:content_partners, :string, :notes, limit: 6000, default: "",
      null: true)
    change_column(:content_partners, :string, :description_of_data,
      limit: 6000, default: "", null: true)
    change_column(:content_partners, :string, :description, limit: 6000,
      default: "", null: true)
    change_column(:content_partners, :string, :full_name, default: "",
      null: true)
    change_column(:content_partners, :string, :admin_notes, default: "",
      limit: 6000,null: true)
  end

  def down
    # Nevermind, I don't care.
  end
end
