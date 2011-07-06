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
     collection_items.sort_by do |item|
       if sort_by == "newest"
         [item.id * -1]
       elsif sort_by == "oldest"
         [item.id]
       end
     end
   end

end
