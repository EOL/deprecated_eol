class AlterResourcesDefaults < ActiveRecord::Migration

  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    default_service_type = ServiceType.create(:label => 'EOL Transfer Schema')
    change_column_default(:resources, :service_type_id, default_service_type.id)
    [:metadata_url, :service_version, :resource_set_code, :logo_url, :language_id, :bibliographic_citation,
     :refresh_period_hours].each do |field|
      change_column_null(:resources, field, true)
    end
    change_column(:resources, :description, :text)
  end

  def self.down
    default_service_type = ServiceType.find_by_label('EOL Transfer Schema')
    ServiceType.delete(default_service_type.id)
    change_column_default(:resources, :service_type_id, nil)
    [:metadata_url, :resource_set_code, :logo_url, :language_id, :bibliographic_citation, :refresh_period_hours,
     :resource_modified_at].each do |field|
      change_column_null(:resources, field, false)
    end
    change_column(:resources, :description, :string, :limit => 400, :null => false)
  end

end
