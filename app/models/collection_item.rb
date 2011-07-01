class CollectionItem < ActiveRecord::Base

  belongs_to :collection
  belongs_to :object, :polymorphic => true

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
