class DataSearchController < ApplicationController

  layout 'v2/data_search'

  # TODO - pass in a known_uri_id when we have it, to avoid the ugly URL
  def index
    @hide_global_search = true
    @querystring = params[:q]
    @attribute = params[:attribute]
    @sort = params[:sort]
    @page = params[:page] || 1
    @attribute = nil unless KnownUri.all_measurement_type_uris.include?(@attribute)
    @attribute_known_uri = KnownUri.find_by_uri(@attribute)
    @from, @to = nil, nil
    # we must at least have an attribute to perform a Virtuoso query, otherwise it would be too slow
    unless @attribute.blank?
      if @querystring && matches = @querystring.match(/^([^ ]+) to ([^ ]+)$/)
        from = matches[1]
        to = matches[2]
        if from.is_numeric? && to.is_numeric?
          @from, @to = [ from.to_f, to.to_f ].sort
        end
      end
    end
    respond_to do |format|
      format.html do
        @results = TaxonData.search(querystring: @querystring, attribute: @attribute, from: @from, to: @to,
          page: @page, sort: @sort, per_page: 30)
      end
      format.js do
        df = DataSearchFile.create!(
          q: @querystring, uri: @attribute, from: @from, to: @to,
          sort: @sort, known_uri: @attribute_known_uri, language: current_language,
          user: current_user.is_a?(EOL::AnonymousUser) ? nil : current_user
        )
        @message = if df.file_exists?
                     I18n.t(:file_ready_for_download, file: df.download_path, query: @querystring)
                   else
                     I18n.t(:file_download_pending)
                   end
        Resque.enqueue(DataFileMaker, data_file_id: df.id)
      end
    end
  end

  private

end
