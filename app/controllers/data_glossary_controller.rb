class DataGlossaryController < ApplicationController

  layout 'v2/basic'

  # GET /data_glossary
  def show
    @page_title = I18n.t(:data_glossary)
  end

end
