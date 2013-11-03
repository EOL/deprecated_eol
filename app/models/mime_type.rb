# Represents a system mime/type.  Used by DataObject.
class MimeType < ActiveRecord::Base

  uses_translations
  has_many :data_objects

  include NamedDefaults
  set_defaults :label, [
    {method_name: :jpg, label: 'image/jpeg'},
    {method_name: :html, label: 'text/html'},
    {method_name: :txt, label: 'text/plain'},
    {method_name: :mp4, label: 'video/mp4'},
    {method_name: :wmv, label: 'video/x-ms-wmv'},
    {method_name: :mpeg, label: 'video/mpeg'},
    {method_name: :mov, label: 'video/quicktime'},
    {method_name: :flv, label: 'video/x-flv'},
    {method_name: :mp3, label: 'audio/mpeg'},
    {method_name: :wav, label: 'audio/x-wav'}
  ]

end
