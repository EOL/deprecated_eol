# NOTE - you can get a list of all the possible collection item types with this command:
# git grep "has_many :collection_items, :as" app
class CollectionItem < ActiveRecord::Base

  belongs_to :collection
  belongs_to :object, :polymorphic => true

  # Note that it doesn't validate the presence of collection.  A "removed" collection item still exists, so we have a
  # record of what it used to point to (see CollectionsController#destroy). (Hey, the alternative is to have a bunch
  # of unused fields in collection_activity_logs, so it's actually better to have these "zombie" rows here!)
  validates_presence_of :object_id, :object_type
  validates_uniqueness_of :object_id, :scope => [:collection_id, :object_type],
    :message => I18n.t(:item_not_added_already_in_collection)

  def self.custom_sort(collection_items, sort_by)
    case sort_by
    when SortStyle.newest.id
      collection_items.sort_by(&:created_at).reverse
    else # THIS IS THE DEAFULT... but if you want to change it, then: when SortStyle.oldest.id
      collection_items.sort_by(&:created_at)
    end
  end

  # Using has_one :through didn't work:
  def community
    return nil unless collection
    return nil unless collection.community
    return collection.community
  end

end
