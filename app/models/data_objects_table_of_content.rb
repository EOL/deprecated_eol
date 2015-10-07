# Denormalized relationship table for speed.
class DataObjectsTableOfContent < ActiveRecord::Base
  belongs_to :data_object
  belongs_to :toc_item, foreign_key: :toc_id
  has_many :data_objects_info_items, through: :data_object
  self.primary_keys = :data_object_id, :toc_id

  # NOTE - this is silly. This is slow. This is dangerous. TODO - remove rows
  # corresponding to harvested data objects as you are harvesting, rebuild those
  # and only those.
  def self.rebuild
    EOL.log_call
    dotocs = Set.new
    # Lousy syntax for a "standard" join in SQL... we want all the rows where
    # there ISN'T a corresponding row in doii:
    where("data_objects_info_items.data_object_id IS NULL").
      joins("LEFT JOIN data_objects_info_items USING (data_object_id)").
      find_in_batches do |batch|
      dotocs += batch.map { |dotoc| "(#{dotoc["data_object_id", "toc_id"].
        join(", ")})" }
    end
    DataObjectsInfoItem.
      where("info_items.toc_id != 0").
      includes(:info_item).
      find_in_batches do |doii|
      dotocs += doii.map { |doii| "#{doii.data_object_id}, "\
        "#{doii.info_item.toc_id}" }
    end
    if dotocs.empty?
      EOL.log("WARNING: Unable to find data object TOC items; skipping.", prefix: '*')
    else
      EOL.log("Found appropriate data object TOC items, rebuilding...", prefix: '.')
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("TRUNCATE TABLE `#{table_name}`")
        EOL::Db.bulk_insert(self, [:data_object_id, :toc_id], dotocs.to_a)
      end
      EOL.log("#rebuild finished; exiting", prefix: '#')
    end
  end
end
