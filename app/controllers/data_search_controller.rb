class DataSearchController < ApplicationController

  layout 'v2/data_search'

  def index
    @querystring = params[:q]
    @attribute = params[:attribute]
    @page = params[:page] || 1
    @attribute = nil unless KnownUri.all_measurement_type_uris.include?(@attribute)
    @from, @to = nil, nil
    if @querystring
      if matches = @querystring.match(/^([^ ]+) to ([^ ]+)$/)
        from = matches[1]
        to = matches[2]
        if from.is_numeric? && to.is_numeric?
          @from, @to = [ from.to_f, to.to_f ].sort
        end
      end
      @results = TaxonData.search(:querystring => @querystring, :attribute => @attribute, :from => @from, :to => @to,
        :page => @page, :per_page => 30)
    end
  end
end
