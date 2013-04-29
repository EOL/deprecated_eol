class Taxa::DataController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def index
    @assistive_section_header = "ASdfsfasdfasdfasdaf" # TODO
    @recently_used = KnownUri.where(['uri IN (?)', session[:rec_uris]]) if session[:rec_uris]
    @data = @taxon_page.data.get_data
    add_known_uris_to_data
    current_user.log_activity(:viewed_taxon_concept_data, :taxon_concept_id => @taxon_concept.id)
  end

protected

  # TODO...
  def meta_description
    @meta_description ||= "this is so meta"
  end

  # TODO - move this to KnownUri (mostly)
  def add_known_uris_to_data
    known_uris = KnownUri.where(["uri in (?)", uris_in_data])
    @data.each do |row|
      attr_uri = known_uris.select { |known_uri| known_uri.uri == row[:attribute] }.first
      val_uri = known_uris.select { |known_uri| known_uri.uri == row[:value] }.first
      row[:attribute] = attr_uri if attr_uri
      row[:value] = val_uri if val_uri
      # Don't modify something when you're iterating over it!
      delete_keys = []
      new_keys = {}
      row[:metadata].each do |key, val|
        # Licenses are special:
        if key == UserAddedDataMetadata::LICENSE_URI.downcase &&
           License.exists?(source_url: row[:metadata][key].to_s)
          new_keys[KnownUri.license] = License.find_by_source_url(row[:metadata][key].to_s).title
          delete_keys << key
          next
        end
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
    uris += @data.map { |row| row[:metadata].keys }.flatten.select { |attr| attr.is_a?(RDF::URI) }
    uris += @data.map { |row| row[:metadata].values }.flatten.select { |attr| attr.is_a?(RDF::URI) }
    uris.map(&:to_s)
  end

end
