class ContentPartner::AsUnassisted < ContentPartner

  after_create :notify_master_curators

  private

  def notify_master_curators
    Notifier.content_partner_created(self, user).deliver
  end

end
