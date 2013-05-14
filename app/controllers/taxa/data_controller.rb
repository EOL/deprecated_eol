class Taxa::DataController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def index
    @assistive_section_header = "ASdfsfasdfasdfasdaf" # TODO
    @recently_used = KnownUri.where(['uri IN (?)', session[:rec_uris]]) if session[:rec_uris]
    @data = replace_licenses_with_mock_known_uris(@taxon_page.data.get_data)
    add_known_uris_to_data
    @categories = @data.map { |d| d[:attribute] }.flat_map { |a| a.is_a?(KnownUri) ? a.toc_items : nil }.uniq.compact
    current_user.log_activity(:viewed_taxon_concept_data, :taxon_concept_id => @taxon_concept.id)
  end

protected

  # TODO...
  def meta_description
    @meta_description ||= "this is so meta"
  end

  def replace_licenses_with_mock_known_uris(data)
    data.each do |row|
      row[:metadata].each do |key, val|
        if key == UserAddedDataMetadata::LICENSE_URI && license = License.find_by_source_url(val.to_s)
          row[:metadata][key] = KnownUri.new(:uri => val,
            :translations => [ TranslatedKnownUri.new(:name => license.title, :language => current_language) ])
        end
      end
    end
    data
  end

  # TODO - move this to KnownUri (mostly)
  def add_known_uris_to_data
    known_uris = KnownUri.where(["uri in (?)", uris_in_data])
    @data.each do |row|
      attr_uri = known_uris.select { |known_uri| known_uri.uri.casecmp(row[:attribute].to_s) == 0 }.first
      val_uri = known_uris.select { |known_uri| known_uri.uri.casecmp(row[:value].to_s) == 0 }.first
      row[:attribute] = attr_uri if attr_uri
      row[:value] = val_uri if val_uri
      # Don't modify something when you're iterating over it!
      delete_keys = []
      new_keys = {}
      row[:metadata].each do |key, val|
        key_uri = known_uris.select { |known_uri| known_uri.uri == key }.first
        val_uri = known_uris.select { |known_uri| known_uri.uri == val }.first
        row[:metadata][key] = val_uri if val_uri
        if key_uri
          new_keys[key_uri] = row[:metadata][key]
          delete_keys << key
        end
      end
      delete_keys.each { |k| row[:metadata].delete(k) }
      new_keys.each { |k,v| row[:metadata][k] = v }
    end
  end

  def uris_in_data
    uris  = @data.map { |row| row[:attribute] }.select { |attr| attr.is_a?(RDF::URI) }
    uris += @data.map { |row| row[:value] }.select { |attr| attr.is_a?(RDF::URI) }
    uris += @data.map { |row| row[:metadata] ? row[:metadata].keys : nil }.flatten.compact.select { |attr| attr.is_a?(RDF::URI) }
    uris += @data.map { |row| row[:metadata] ? row[:metadata].values : nil }.flatten.compact.select { |attr| attr.is_a?(RDF::URI) }
    uris.map(&:to_s).uniq
  end

end
