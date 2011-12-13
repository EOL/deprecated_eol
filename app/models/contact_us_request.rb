class ContactUsRequest < ActiveRecord::Base
  belongs_to :topic_area

  @email_format_re = %r{^(?:[_\+a-z0-9-]+)(\.[_\+a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4})$}i

  validates_presence_of     :first_name, :last_name, :email
  
  def full_name
    first_name + " " + last_name
  end
end
