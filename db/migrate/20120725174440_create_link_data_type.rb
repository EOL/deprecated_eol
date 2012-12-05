class CreateLinkDataType < ActiveRecord::Migration
  def self.up
    unless DataType.link
      dt = DataType.create!(:schema_value => 'Link')
      TranslatedDataType.create!(:data_type_id => dt.id, :language_id => Language.default.id, :label => 'Link')
    end
  end

  def self.down
    # Nothing to do.
  end
end
