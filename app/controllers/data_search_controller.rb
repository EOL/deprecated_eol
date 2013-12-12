class DataSearchController < ApplicationController

  before_filter :restrict_to_data_viewers

  layout 'v2/data_search'

  # TODO - pass in a known_uri_id when we have it, to avoid the ugly URL
  def index
    @hide_global_search = true
    @querystring = params[:q]
    @attribute = params[:attribute]
    @sort = params[:sort]
    @page = params[:page] || 1
    @attribute = nil unless EOL::Sparql.connection.all_measurement_type_uris.include?(@attribute)
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
    search_options = { querystring: @querystring, attribute: @attribute, from: @from, to: @to,
      sort: @sort, language: current_language }
    respond_to do |format|
      format.html do
        @results = TaxonData.search(search_options.merge(page: @page, per_page: 30))
      end
      format.csv do    # Direct download... (implies DataSearchFile might be misnamed...)
        df = create_data_search_file
        # TODO - handle the case where results are empty. Also, 
        # http://stackoverflow.com/questions/5844033/rails-3-format-csv-gives-no-template-error-but-format-json-needs-no-template
        # ...would be a more elegant solution, if we wanna keep doing this.
        headers["Content-Disposition"] = "attachment; filename=\"#{df.filename}\""
        render text: df.csv(host: request.host)
      end
      format.js do   # Background download...
        df = create_data_search_file
        @message = if df.hosted_file_exists?
                     I18n.t(:file_download_ready, file: df.download_path, query: @querystring)
                   else
                     I18n.t(:file_download_pending, link: data_search_files_path)
                   end
        Resque.enqueue(DataFileMaker, data_file_id: df.id)
      end
    end
  end

  private

  def create_data_search_file
    DataSearchFile.create!(
      q: @querystring, uri: @attribute, from: @from, to: @to,
      sort: @sort, known_uri: @attribute_known_uri, language: current_language,
      user: current_user.is_a?(EOL::AnonymousUser) ? nil : current_user
    )
  end

end
