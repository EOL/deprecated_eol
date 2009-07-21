class DataObjectsUntrustReason < SpeciesSchemaModel
  belongs_to :untrust_reason
  belongs_to :data_object

  validates_presence_of :data_object_id, :untrust_reason_id
  validates_uniqueness_of :data_object_id, :scope => :untrust_reason_id
end