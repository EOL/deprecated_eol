class DataSearchController < ApplicationController

  layout 'v2/data_search'

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
      format.csv do
        # TODO - really, we shouldn't use pagination at all, here.
        @results = TaxonData.search(querystring: @querystring, attribute: @attribute, from: @from, to: @to,
          sort: @sort, per_page: 30000) # TODO - if we KEEP pagination, make this value more sane (and put @page back in).
        # TODO - handle the case where results are empty.
        render text: build_csv_from_results
      end
    end
  end

  private

  def build_csv_from_results
    rows = []
    @results.each do |data_point_uri|
      rows << data_point_uri.to_hash(current_language)
    end
    col_heads = Set.new
    rows.each do |row|
      col_heads.merge(row.keys)
    end
    Rails.cache.fetch("download_data/#{@querystring}/#{@attribute}/#{@from}-#{@to}/#{@sort}") do
      CSV.generate do |csv|
        csv << col_heads
        rows.each do |row|
          csv << col_heads.inject([]) { |a, v| a << row[v] } # A little magic to sort the values...
        end
      end
    end
  end

end
