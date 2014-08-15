# encoding: utf-8

class ContentPartner
  # Contextual model for self-created content partners
  class AsUnassisted < ActiveType::Record[ContentPartner]
    after_create :notify_master_curators

    private

    def notify_master_curators
      Notifier.content_partner_created(self, user).deliver
    end
  end
end
