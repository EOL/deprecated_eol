class DataGlossaryController < ApplicationController

  before_filter :restrict_to_data_viewers

  layout 'basic'

  # GET /data_glossary
  def show
    @page_title = I18n.t(:data_glossary)
    respond_to do |format|
      format.html {}
      format.js { render text: KnownUri.glossary_terms.select { |uri| ! uri.definition.blank? }.to_json }
    end
  end

end
