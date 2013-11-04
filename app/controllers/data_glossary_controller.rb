class DataGlossaryController < ApplicationController

  before_filter :restrict_to_data_viewers

  layout 'v2/basic'

  # GET /data_glossary
  def show
    @page_title = I18n.t(:data_glossary)
    @known_uris = KnownUri.all.delete_if { |ku| ku.name.blank? }
  end

end
