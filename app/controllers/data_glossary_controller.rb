class DataGlossaryController < ApplicationController

  layout 'basic'

  # GET /data_glossary
  def show
    @page_title = I18n.t(:data_glossary)
    respond_to do |format|
      format.html {}
      format.js do
        json = Rails.cache.fetch("data_glossary", expires_in: 1.week) do
          KnownUri.glossary_terms.select { |uri| ! uri.definition.blank? }.to_json
        end
        render text: json
      end
    end
  end

end
