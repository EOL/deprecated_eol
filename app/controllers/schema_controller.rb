class SchemaController < ApplicationController

  before_filter :restrict_to_data_viewers

  def terms
    if known_uri = KnownUri.find_by_uri(Rails.configuration.schema_terms_prefix + params[:id])
      redirect_to data_glossary_url(:anchor => known_uri.anchor)
      return
    end
    raise ActiveRecord::RecordNotFound
  end

end
