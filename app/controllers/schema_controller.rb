class SchemaController < ApplicationController

  def terms
    if known_uri = KnownUri.by_uri(Rails.configuration.uri_term_prefix + params[:id])
      redirect_to data_glossary_url(anchor: known_uri.anchor)
      return
    end
    raise ActiveRecord::RecordNotFound
  end

end
