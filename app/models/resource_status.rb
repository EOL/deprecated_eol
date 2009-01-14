class ResourceStatus < SpeciesSchemaModel
  has_many :resources

  def self.uploading
    @@uploading ||= self.find_by_label('Uploading') 
  end
  
  def self.uploaded
    @@uploaded ||= self.find_by_label('Uploaded')
  end
  
  def self.upload_failed
    @@upload_failed ||= self.find_by_label('Upload Failed')
  end
  
  def self.moved_to_content_server
    @@moved_to_content_server ||= self.find_by_label('Moved to Content Server')
  end
  
  def self.validated
    @@validated ||= self.find_by_label('Validated')
  end
  
  def self.validation_failed
    @@validation_failed ||= self.find_by_label('Validation Failed')
  end
  
  def self.being_processed
    @@being_processed ||= self.find_by_label('Being Processed')
  end
  
  def self.processed
    @@processed ||= self.find_by_label('Processed')
  end
  
  def self.processing_failed
    @@processing_failed ||= self.find_by_label('Processing Failed')
  end

  def self.published
    @@published ||= self.find_by_label('Published')
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

