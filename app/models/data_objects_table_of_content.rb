# Denormalized relationship table for speed.
class DataObjectsTableOfContent < ActiveRecord::Base
  belongs_to :data_object
  belongs_to :toc_item, foreign_key: :toc_id
  has_many :data_objects_info_items, through: :data_object
  self.primary_keys = :data_object_id, :toc_id

  def self.rebuild_by_ids(ids)
    EOL.log_call
    new_ids = Set.new(ids)
    old_ids = Set.new
    dotocs = Set.new
    # Lousy syntax for a "standard" join in SQL... we want all the rows where
    # there ISN'T a corresponding row in doii:
    where(["data_objects_table_of_contents.data_object_id IN (?) AND "\
      "data_objects_info_items.data_object_id IS NULL", ids]).
      joins("LEFT JOIN data_objects_info_items USING (data_object_id)").
      find_in_batches do |batch|
      dotocs += batch.map { |dotoc| "#{dotoc["data_object_id"]}, #{dotoc["toc_id"]}" }
    end
    DataObjectsInfoItem.
      where(["info_items.toc_id != 0 AND data_object_id IN (?)", ids]).
      includes(:info_item).
      find_in_batches do |batch|
      batch.each do |doii|
        dotocs << "#{doii.data_object_id}, #{doii.info_item.toc_id}" }
        old_ids << doii.data_object_id
      end
    end
    if dotocs.empty?
      EOL.log("WARNING: Unable to find data object TOC items; skipping.", prefix: '*')
    else
      EOL.log("Found appropriate data object TOC items, rebuilding...", prefix: '.')
      ActiveRecord::Base.transaction do
        # YOU WERE HERE: this doesn't work. Shoot. We need to find all the old ones. Crappy.
        Can we just use "ids" (again) and only delete them if the ID is ALSO in the dotocs? I like that idea.
        updated_ids = old_ids.intersection(new_ids).to_a
        # NOTE: Believe it or not, even though these are the "primary keys",
        # this query is VERY VERY SLOW. With only ONE pair, it takes 8 seconds
        # to run. Fun stuff.
        where(id: updated_ids).delete_all
        EOL::Db.bulk_insert(self, [:data_object_id, :toc_id], dotocs.to_a)
      end
      EOL.log_return
    end
  end
end
