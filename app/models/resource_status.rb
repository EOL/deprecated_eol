class ResourceStatus < ActiveRecord::Base
  uses_translations
  has_many :resources

  def self.being_processed
    cached_find_translated(:label, 'Being Processed', 'en')
  end

  def self.force_harvest
    cached_find_translated(:label, 'Force Harvest', 'en')
  end

  def self.moved_to_content_server
    cached_find_translated(:label, 'Moved to Content Server', 'en')
  end

  def self.processed
    cached_find_translated(:label, 'Processed', 'en')
  end

  def self.processing_failed
    cached_find_translated(:label, 'Processing Failed', 'en')
  end

  def self.uploading
    cached_find_translated(:label, 'Uploading', 'en')
  end

  def self.uploaded
    cached_find_translated(:label, 'Uploaded', 'en')
  end

  def self.upload_failed
    cached_find_translated(:label, 'Upload Failed', 'en')
  end

  def self.validated
    cached_find_translated(:label, 'Validated', 'en')
  end

  def self.validation_failed
    cached_find_translated(:label, 'Validation Failed', 'en')
  end

  def self.published
    cached_find_translated(:label, 'Published', 'en')
  end

end
