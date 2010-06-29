class ResourceStatus < SpeciesSchemaModel
  has_many :resources

  def self.being_processed
    cached_find(:label, 'Being Processed')
  end
  
  def self.force_harvest
    cached_find(:label, 'Force Harvest')
  end
  
  def self.moved_to_content_server
    cached_find(:label, 'Moved to Content Server')
  end
  
  def self.processed
    cached_find(:label, 'Processed')
  end
  
  def self.processing_failed
    cached_find(:label, 'Processing Failed')
  end

  def self.published
    cached_find(:label, 'Published')
  end
  
  def self.publish_pending
    cached_find(:label, 'Publish Pending')
  end
  
  def self.uploading
    cached_find(:label, 'Uploading')
  end
  
  def self.uploaded
    cached_find(:label, 'Uploaded')
  end
  
  def self.upload_failed
    cached_find(:label, 'Upload Failed')
  end
  
  def self.validated
    cached_find(:label, 'Validated')
  end
  
  def self.validation_failed
    cached_find(:label, 'Validation Failed')
  end
  
  def self.unpublish_pending
    cached_find(:label, 'Unpublish Pending')
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

