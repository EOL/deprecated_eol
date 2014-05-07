class DataGlossaryController < ApplicationController

  before_filter :restrict_to_data_viewers

  layout 'basic'

  # GET /data_glossary
  def show
    @page_title = I18n.t(:data_glossary)
  end

end
