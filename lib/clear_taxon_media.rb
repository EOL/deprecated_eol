class ClearTaxonMedia

  # TODO - we might want to pick a different queue, but that means setting it up:
  @queue = 'notifications'

  def self.perform(id)
    tc = TaxonConcept.find(id)
    puts "++ #{Time.now.strftime("%F %T")} - ClearTaxonMedia performing for TC##{tc.id}."
    TaxonConceptCacheClearing.clear(tc)
    TaxonConceptCacheClearing.clear_media(tc)
    puts "++ #{Time.now.strftime("%F %T")} - ClearTaxonMedia for TC##{tc.id} Done."
  end

end
