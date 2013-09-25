class DataSearchController < ApplicationController

  layout 'v2/data_search'

  def index
    @querystring = params[:q]
    @attribute = params[:attribute]
    @sort = params[:sort]
    @page = params[:page] || 1
    @attribute = nil unless KnownUri.all_measurement_type_uris.include?(@attribute)
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
      @results = TaxonData.search(querystring: @querystring, attribute: @attribute, from: @from, to: @to,
        page: @page, sort: @sort, per_page: 30)
    end
    respond_to do |format|
      format.html {}
      format.csv { render text: build_csv_from_results } # TODO - handle the case where results are empty.
    end
  end

  private

  # TODO - we don't actually want to do this when building CSV, since we have pagination and don't want it. This is just a test!
  def build_csv_from_results
    CSV.generate do |csv|
      csv << DataPointUri.csv_columns(current_language)
      @results.each do |data_point_uri|
        csv << data_point_uri.csv_values(current_language)
      end
    end
  end

end
