class ResourceStatus < SpeciesSchemaModel
  has_many :resources

  def self.uploading
    YAML.load(Rails.cache.fetch('resource_statuses/uploading') do
      self.find_by_label('Uploading').to_yaml
    end)
  end
  
  def self.uploaded
    YAML.load(Rails.cache.fetch('resource_statuses/uploaded') do
      self.find_by_label('Uploaded').to_yaml
    end)
  end
  
  def self.upload_failed
    YAML.load(Rails.cache.fetch('resource_statuses/upload_failed') do
      self.find_by_label('Upload Failed').to_yaml
    end)
  end
  
  def self.moved_to_content_server
    YAML.load(Rails.cache.fetch('resource_statuses/moved_to_content_server') do
      self.find_by_label('Moved to Content Server').to_yaml
    end)
  end
  
  def self.validated
    YAML.load(Rails.cache.fetch('resource_statuses/validated') do
      self.find_by_label('Validated').to_yaml
    end)
  end
  
  def self.validation_failed
    YAML.load(Rails.cache.fetch('resource_statuses/validation_failed') do
      self.find_by_label('Validation Failed').to_yaml
    end)
  end
  
  def self.being_processed
    YAML.load(Rails.cache.fetch('resource_statuses/being_processed') do
      self.find_by_label('Being Processed').to_yaml
    end)
  end
  
  def self.processed
    YAML.load(Rails.cache.fetch('resource_statuses/processed') do
      self.find_by_label('Processed').to_yaml
    end)
  end
  
  def self.processing_failed
    YAML.load(Rails.cache.fetch('resource_statuses/processing_failed') do
      self.find_by_label('Processing Failed').to_yaml
    end)
  end

  def self.published
    YAML.load(Rails.cache.fetch('resource_statuses/published') do
      self.find_by_label('Published').to_yaml
    end)
  end
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: resource_statuses
#
#  id         :integer(4)      not null, primary key
#  label      :string(255)
#  created_at :datetime
#  updated_at :datetime

