class ContentPartnersAddDefaults < ActiveRecord::Migration
  def up
    # TODO: This may not work; you may have to lower these 6000s to 5000s.
    change_column(:content_partners, :notes, :string, limit: 5000, default: "",
      null: true)
    change_column(:content_partners, :description_of_data, :string,
      limit: 5000, default: "", null: true)
    change_column(:content_partners, :description, :string, limit: 5000,
      default: "", null: true)
    change_column(:content_partners, :full_name, :string, default: "",
      null: true)
    change_column(:content_partners, :admin_notes, :string, default: "",
      limit: 5000,null: true)
  end

  def down
    # Nevermind, I don't care.
  end
end
