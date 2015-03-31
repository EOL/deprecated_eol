class ResourceStatus < ActiveRecord::Base

  uses_translations
  has_many :resources

  include Enumerated
  enumerated :label, [
    'Being Processed',
    'Force Harvest',
    'Moved to Content Server',
    'Processed',
    'Processing Failed',
    'Uploading',
    'Uploaded',
    'Upload Failed',
    'Validated',
    'Validation Failed',
    'Published',
    'Obsolete'
  ]

end
