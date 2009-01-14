class Contact < ActiveRecord::Base
  
  validates_presence_of :name, :comments
  validates_presence_of :contact_subject, :message=>'^' + 'Please select a topic area'[:select_topic]

 # validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i    
  after_create :send_contact_email
  belongs_to :contact_subject
  
  ## dummy example of how to write inline SQL in a model that runs a complex sql query using a parameter as an input, and then concatenates the results
 # def self.report(id=100)
   
 #   response1=self.find_by_sql(["select contacts.id,name,title from contacts inner join contact_subjects on contacts.contact_subject_id=contact_subjects.id where contacts.id < ?",id])
 #   response2=self.find_by_sql(["select contacts.id,name,title from contacts inner join contact_subjects on contacts.contact_subject_id=contact_subjects.id where contacts.id > ?",id])
    # cross-database join
 #   response3=self.find_by_sql("select contacts.id,name,namestring as title from contacts inner join union_editor.names_holdings on contacts.id=union_editor.names_holdings.id where contacts.id")
   
    #mysqlresult = ClassificationSchemaModel.connection.execute('select * from Chresonym where citationsID=1531')

 #   return response1+response2+response3
    
    #Contact.report(5).each {|r| puts r.id.to_s + ',' + r.name + ',' + r.title}
    
 # end
  
  protected
  
    def send_contact_email
      Notifier::deliver_contact_email(self)
    end
    
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: contacts
#
#  id                 :integer(4)      not null, primary key
#  contact_subject_id :integer(4)
#  user_id            :string(255)
#  comments           :text
#  email              :string(255)
#  ip_address         :string(255)
#  name               :string(255)
#  referred_page      :string(255)
#  taxon_group        :string(255)
#  created_at         :datetime
#  updated_at         :datetime

