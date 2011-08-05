class ContentPartnersController < ApplicationController

  layout 'v2/partners'

  # GET /content_partners/:content_partner_id/contacts/new
  def new
    @partner = ContentPartner.find(params[:id])
    @new_content_partner_contact = @partner.content_partner_contacts.build
  end

  # POST /content_partners/:content_partner_id/contacts
  def create

  end

  # GET /content_partners/:content_partner_id/contacts/:id/edit
  def edit
    @partner = ContentPartner.find(params[:id])

  end

  # PUT /content_partners/:content_partner_id/contacts/:id
  def update

  end

  # DELETE /content_partners/:content_partner_id/contacts/:id
  def destroy

  end

end
