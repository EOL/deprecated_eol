class GlossaryController < ApplicationController

  layout 'v2/basic'

  # GET /glossary
  def show
    @known_uris = KnownUri.all
    @known_uris.delete_if{ |ku| ku.name.blank? }
    @page_title = "Glossary"
  end

end
