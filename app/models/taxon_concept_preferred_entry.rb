class TaxonConceptPreferredEntry < ActiveRecord::Base
  belongs_to :taxon_concept
  belongs_to :hierarchy_entry
  
  # TODO: I want an insert delayed, is there any other way but a custom one?
  def self.create(opts={})
    return nil if !opts || opts.class != Hash
    opts.delete_if{ |k,v| !self.column_names.include?(k.to_s) }
    return nil if opts.blank?
    
    if opts[:taxon_concept_id]
      connection.execute "DELETE FROM taxon_concept_preferred_entries WHERE taxon_concept_id=#{connection.quote(opts[:taxon_concept_id])}"
    end
    field_names = opts.keys.collect{ |k| k.to_s }.join(', ')
    field_values = opts.values.collect{ |k| connection.quote(k) }.join(', ')
    connection.execute "INSERT DELAYED INTO taxon_concept_preferred_entries (#{ field_names }) VALUES (#{ field_values })"
  end
  
  def self.expire_time
    1.week
  end
  
  def expired?
    return true if !self.updated_at
    ( self.updated_at + TaxonConceptPreferredEntry.expire_time ) < Time.now()
  end
end
