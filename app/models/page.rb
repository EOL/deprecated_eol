# This is a class used by Tramea. It's NOT in the database; it's too close to a
# taxon_concept to bother storing.
class Page < TaxonConcept
  def self.denormalize_taxon_concept(taxon)
    Summary.from_taxon_concept(taxon)
    taxon.hierarchy_entries.map do |entry|
      Node.from_hierarchy_entry(entry)
    end
    # There's no need to add data point uris: we have them. However, we DO need
    # to manage the metadata, which probably have NOT been added, yet. NOTE that
    # this is EXPENSIVE!
    TaxonData.new(taxon).get_data.each do |uri|
      Metadatum.from_data_point_uri(uri)
    end
    # #data_objects appears to still be trustworthy, so I'm using it.
    taxon.data_objects.each do |data|
      # Yes, this adds a lot more (for each relationship from the data), but we
      # check to see if it exists before adding one, so this will save us (a
      # little) time down the road:
      case data.data_type
      when DataType.image
        Image.from_data_object(data)
      when DataType.sound
        Rails.logger.error("Skipping Sound #{data.id}")
      when DataType.text
        Article.from_data_object(data)
      when DataType.video
        Rails.logger.error("Skipping Video #{data.id}")
      when DataType.iucn
        next # We have this in the traits.
      when DataType.flash
        Rails.logger.error("Skipping Flash #{data.id}")
      when DataType.youtube
      when DataType.gbif_image
        Rails.logger.error("Skipping GBIF Images #{data.id}")
      when DataType.map
        Rails.logger.error("Skipping map #{data.id}")
      when DataType.link
        Rails.logger.error("Skipping link #{data.id}")
      end
    end
  end
end
