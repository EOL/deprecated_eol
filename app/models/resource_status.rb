class ResourceStatus < SpeciesSchemaModel
  has_many :resources

  def self.uploading
    Rails.cache.fetch(:uploading_res_status) do
      self.find_by_label('Uploading') 
    end
  end
  
  def self.uploaded
    Rails.cache.fetch(:uploaded_res_status) do
      self.find_by_label('Uploaded')
    end
  end
  
  def self.upload_failed
    Rails.cache.fetch(:upload_failed_res_status) do
      self.find_by_label('Upload Failed')
    end
  end
  
  def self.moved_to_content_server
    Rails.cache.fetch(:moved_to_content_server_res_status) do
      self.find_by_label('Moved to Content Server')
    end
  end
  
  def self.validated
    Rails.cache.fetch(:validated_res_status) do
      self.find_by_label('Validated')
    end
  end
  
  def self.validation_failed
    Rails.cache.fetch(:validation_failed_res_status) do
      self.find_by_label('Validation Failed')
    end
  end
  
  def self.being_processed
    Rails.cache.fetch(:being_processed_res_status) do
      self.find_by_label('Being Processed')
    end
  end
  
  def self.processed
    Rails.cache.fetch(:processed_res_status) do
      self.find_by_label('Processed')
    end
  end
  
  def self.processing_failed
    Rails.cache.fetch(:processing_failed_res_status) do
      self.find_by_label('Processing Failed')
    end
  end

  def self.published
    Rails.cache.fetch(:published_res_status) do
      self.find_by_label('Published')
    end
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

