class KnownUriRelationshipsController < ApplicationController

  before_filter :restrict_to_admins

  # POST /known_uri_relationships
  def create
    if params[:known_uri_relationship][:to_known_uri_id].blank? && params[:autocomlete][:to_known_uri]
      if known_uri = KnownUri.by_uri(params[:autocomplete][:to_known_uri].strip)
        params[:known_uri_relationship][:to_known_uri_id] = known_uri.id
      end
    end
    @known_uri_relationship = KnownUriRelationship.new(params[:known_uri_relationship])
    if @known_uri_relationship.save
      flash[:notice] = I18n.t('known_uri_relationships.created')
    else
      flash[:error] = I18n.t('known_uri_relationships.create_failed')
      flash[:error] << " #{@known_uri_relationship.errors.full_messages.join('; ')}." if @known_uri_relationship.errors.any?
    end
    redirect_to edit_known_uri_path(@known_uri_relationship.from_known_uri)
  end

  # DELETE /known_uri_relationships/:id
  def destroy
    @known_uri_relationship = KnownUriRelationship.find(params[:id])
    @known_uri_relationship.destroy
    flash[:notice] = I18n.t('known_uri_relationships.deleted')
    redirect_to request.referer
  end
end
