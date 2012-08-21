class Contact < ActiveRecord::Base

  belongs_to :contact_subject

  validates_presence_of :name, :comments, :email, :contact_subject
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i

  after_create :send_contact_email

  private

  def send_contact_email
    Notifier.contact_us_message(self).deliver
  end

end
