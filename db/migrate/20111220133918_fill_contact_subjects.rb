class FillContactSubjects < ActiveRecord::Migration
  def self.up
    ContactSubject.reset_column_information
    ContactSubject.delete_all
    TranslatedContactSubject.delete_all
    
    english = Language.english_for_migrations
    cs = ContactSubject.create(:recipients => "membership@eol.org", :active => 1)
    TranslatedContactSubject.create(:contact_subject => cs, :language => english, :title => 'Membership and registration')
    
    cs = ContactSubject.create(:recipients => "legal@eol.org", :active => 1)
    TranslatedContactSubject.create(:contact_subject => cs, :language => english, :title => 'Terms of use and licensing')
    
    cs = ContactSubject.create(:recipients => "education@eol.org", :active => 1)
    TranslatedContactSubject.create(:contact_subject => cs, :language => english, :title => 'Learning and education')
    
    cs = ContactSubject.create(:recipients => "eolpages@eol.org", :active => 1)
    TranslatedContactSubject.create(:contact_subject => cs, :language => english, :title => 'Become a content partner')
    
    cs = ContactSubject.create(:recipients => "eolpages@eol.org", :active => 1)
    TranslatedContactSubject.create(:contact_subject => cs, :language => english, :title => 'Content partner support')
    
    cs = ContactSubject.create(:recipients => "eolpages@eol.org", :active => 1)
    TranslatedContactSubject.create(:contact_subject => cs, :language => english, :title => 'Curator support')
    
    cs = ContactSubject.create(:recipients => "eolpages@eol.org", :active => 1)
    TranslatedContactSubject.create(:contact_subject => cs, :language => english, :title => 'Make a correction (spelling and grammar, images, information)')
    
    cs = ContactSubject.create(:recipients => "eolpages@eol.org", :active => 1)
    TranslatedContactSubject.create(:contact_subject => cs, :language => english, :title => 'Contribute images, videos or sounds')
    
    cs = ContactSubject.create(:recipients => "press@eol.org", :active => 1)
    TranslatedContactSubject.create(:contact_subject => cs, :language => english, :title => 'Media requests (interviews, press inquiries, logo requests)')
    
    cs = ContactSubject.create(:recipients => "support@eol.org", :active => 1)
    TranslatedContactSubject.create(:contact_subject => cs, :language => english, :title => 'Make a financial donation')
    
    cs = ContactSubject.create(:recipients => "tech@eol.org", :active => 1)
    TranslatedContactSubject.create(:contact_subject => cs, :language => english, :title => 'Technical questions (problems with search, website functionality)')
    
    cs = ContactSubject.create(:recipients => "support@eol.org", :active => 1)
    TranslatedContactSubject.create(:contact_subject => cs, :language => english, :title => 'General feedback')
  end

  def self.down
    ContactSubject.delete_all
    TranslatedContactSubject.delete_all
  end
end