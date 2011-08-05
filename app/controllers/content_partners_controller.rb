class ContentPartnersController < ApplicationController

  before_filter :check_authentication, :except => [:show]

  layout 'v2/partners'

  def index

  end

  def new

  end

  # GET /content_partners/:id
  def show
    @partner = ContentPartner.find(params[:id])
    @partner_contacts = @partner.content_partner_contacts.select{|cpc| cpc.can_be_read_by?(current_user)}
    @new_partner_contact = @partner.content_partner_contacts.build
    @head_title = @partner.name
  end

  def edit
    @partner = ContentPartner.find(params[:id])
    @head_title = @partner.name
  end

end