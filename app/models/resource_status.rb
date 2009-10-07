class ResourceStatus < SpeciesSchemaModel
  has_many :resources

  def self.being_processed
    Rails.cache.fetch('resource_statuses/being_processed') do
      self.find_by_label('Being Processed')
    end
  end
  
  def self.force_harvest
    Rails.cache.fetch('resource_statuses/force_harvest') do
      self.find_by_label('Force Harvest')
    end
  end
  
  def self.moved_to_content_server
    Rails.cache.fetch('resource_statuses/moved_to_content_server') do
      self.find_by_label('Moved to Content Server')
    end
  end
  
  def self.processed
    Rails.cache.fetch('resource_statuses/processed') do
      self.find_by_label('Processed')
    end
  end
  
  def self.processing_failed
    Rails.cache.fetch('resource_statuses/processing_failed') do
      self.find_by_label('Processing Failed')
    end
  end

  def self.published
    Rails.cache.fetch('resource_statuses/published') do
      self.find_by_label('Published')
    end
  end
  
  def self.publish_pending
    Rails.cache.fetch('resource_statuses/publish_pending') do
      self.find_by_label('Publish Pending')
    end
  end
  
  def self.uploading
    Rails.cache.fetch('resource_statuses/uploading') do
      self.find_by_label('Uploading')
    end
  end
  
  def self.uploaded
    Rails.cache.fetch('resource_statuses/uploaded') do
      self.find_by_label('Uploaded')
    end
  end
  
  def self.upload_failed
    Rails.cache.fetch('resource_statuses/upload_failed') do
      self.find_by_label('Upload Failed')
    end
  end
  
  def self.validated
    Rails.cache.fetch('resource_statuses/validated') do
      self.find_by_label('Validated')
    end
  end
  
  def self.validation_failed
    Rails.cache.fetch('resource_statuses/validation_failed') do
      self.find_by_label('Validation Failed')
    end
  end
  
  def self.unpublish_pending
    Rails.cache.fetch('resource_statuses/unpublish_pending') do
      self.find_by_label('Unpublish Pending')
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

