# This is a class used by Tramea.
#
#   t.integer :data_point_uri_id # This is the subject.
#   t.string :predicate
#   t.string :object
#   t.timestamps
# end
# add_index :metadata, :data_point_uri_id
# add_index :metadata, [:data_point_uri_id, :predicate, :object],
#   name: "from_meta", unique: true
#
class Metadatum < ActiveRecord::Base
  belongs_to :data_point_uri

  def self.from_data_point_uri(uri)
    uri.get_metadata(Language.default).each do |meta|
      from_meta(meta, uri)
    end
  end

  def self.from_meta(meta, uri)
    return find_by_data_point_uri_id_and_object_and_predicate(
    ) if exists?(data_point_uri_id: uri.id,
      predicate: meta.predicate,
      object: meta.object)
    create(
      data_point_uri_id: uri.id,
      predicate: meta.predicate,
      object: meta.object
    )
  end
end
