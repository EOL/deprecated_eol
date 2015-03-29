# This is a class used by Tramea.
#
#   t.integer :resource_id, null: false
#   t.integer :content_partner_id, null: false
#   t.string :name # Denormalized from the resource.
#   t.boolean :browsable, default: false
# end
# add_index :sources, :resource_id
# add_index :sources, :content_partner_id
#
class Source < ActiveRecord::Base
  has_many :nodes

  def self.from_resource(resource)
    return find_by_resource_id(resource.id) if
      exists?(resource_id: resource.id)
    create(
      resource_id: resource.id,
      content_partner_id: resource.content_partner.id,
      name: resource.title,
      browsable: resource.hierarchy.browsable?
    )
  end
end
