class Taxa::DataController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def index
    @assistive_section_header = "ASdfsfasdfasdfasdaf" # TODO
    @data = @taxon_page.data.get_data
    add_known_uris_to_data
    current_user.log_activity(:viewed_taxon_concept_data, :taxon_concept_id => @taxon_concept.id)
  end

protected

  # TODO...
  def meta_description
    @meta_description ||= "this is so meta"
  end

  def add_known_uris_to_data
    known_uris = KnownUri.where(["uri in (?)", uris_in_data])
    @data.each do |row|
      attr_uri = known_uris.select { |known_uri| known_uri.uri == row[:attribute] }.first
      val_uri = known_uris.select { |known_uri| known_uri.uri == row[:value] }.first
      row[:attribute] = attr_uri if attr_uri
      row[:value] = val_uri if val_uri
    end
  end

  def uris_in_data
    uris = @data.map { |row| row[:attribute].to_s }.select { |attr| EOL::Sparql.is_uri?(attr) }
    uris += @data.map { |row| row[:value].to_s }.select { |val| EOL::Sparql.is_uri?(val) }
  end

end
