class TaxonConceptPreferredEntry < ActiveRecord::Base
  belongs_to :taxon_concept
  belongs_to :hierarchy_entry

  def self.expire_time
    1.week
  end

  def self.rebuild
    builder = TaxonConceptPreferredEntry::Rebuilder.new
    builder.rebuild
  end

  def expired?
    return true if !self.updated_at
    ( self.updated_at + TaxonConceptPreferredEntry.expire_time ) < Time.now()
  end
end
