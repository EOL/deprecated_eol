# An ancestry tree for hierarchy entries. It's a bit absurd to me that
# hierarchy_id isn't in the fields. It's also crazy that we don't index
# individual fields (just the PK, which is the combo)... but so far, things
# aren't _that_ slow, so we perservere.
class HierarchyEntriesFlattened < ActiveRecord::Base
  self.table_name = "hierarchy_entries_flattened"
  self.primary_keys = :hierarchy_entry_id, :ancestor_id

  belongs_to :hierarchy_entry, class_name: HierarchyEntry.to_s, foreign_key: :hierarchy_entry_id
  belongs_to :ancestor, class_name: HierarchyEntry.to_s, foreign_key: :ancestor_id

  class << self
    def delete_set(id_pairs)
      return if id_pairs.empty?
      ids_array = id_pairs.to_a.map { |pair| "(#{pair})" }
      size = ids_array.size
      count = 0
      ids_array.in_groups_of(1000, false) do |group|
        this_size = group.size
        count += this_size
        EOL.log("#delete_set working on #{this_size}/#{size} (#{count/size.to_f}%)") if
          size > 10_000
        where("(hierarchy_entry_id, ancestor_id) IN (#{group.join(",")})").
          delete_all
      end
      EOL.log("#delete_set done.") if size > 10_000
      count
    end

    # This is how a hierarchy gets its ancestry_set. It's not very fast, but
    # should only be used during harvesting (and it should be cached after it's
    # called):
    def pks_in_hierarchy(hierarchy)
      pks = Set.new
      ids = hierarchy.hierarchy_entries.pluck(:id)
      num = 0
      done = 0
      ids.in_groups_of(10_000).each do |group|
        EOL.log("pks_in_hierarchy/#{hierarchy.label} (#{hierarchy.id}) "\
          "(#{done += group.size}/#{ids.size})") if ids.size > 10_000
        # NOTE: This was going REALLY (!!!) slow, so I am skipping it for now:
        # pks += EOL.pluck_pks(self, where(hierarchy_entry_id: group))
        pks += where(hierarchy_entry_id: group).map do |hef|
          "#{hef.hierarchy_entry_id},#{hef.ancestor_id}"
        end
      end
      pks
    end
  end

  # TODO: This should really be an aliased attribute (I think), but I'm in a rush.
  def flat_ancestor
    ancestor
  end
end
