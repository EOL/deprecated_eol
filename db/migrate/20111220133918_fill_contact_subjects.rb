class FillContactSubjects < ActiveRecord::Migration
  def self.up
    ContactSubject.create(:recipients => "byrnesb@si.edu",:active => 1)
    ContactSubject.create(:recipients => "byrnesb@si.edu",:active => 1)
    ContactSubject.create(:recipients => "Education@eol.org",:active => 1)
    ContactSubject.create(:recipients => "affiliate@eol.org",:active => 1)
    ContactSubject.create(:recipients => "affiliate@eol.org",:active => 1)
    ContactSubject.create(:recipients => "affiliate@eol.org",:active => 1)
    ContactSubject.create(:recipients => "affiliate@eol.org",:active => 1)
    ContactSubject.create(:recipients => "affiliate@eol.org",:active => 1)
    ContactSubject.create(:recipients => "byrnesb@si.edu",:active => 1)
    ContactSubject.create(:recipients => "byrnesb@si.edu",:active => 1)
    TranslatedContactSubject.create(:contact_subject_id => 1, :language_id => 1, :title => 'Membership and registration')
    TranslatedContactSubject.create(:contact_subject_id => 2, :language_id => 1, :title => 'Terms of use and licensing')
    TranslatedContactSubject.create(:contact_subject_id => 3, :language_id => 1, :title => 'Learning and education tools')
    TranslatedContactSubject.create(:contact_subject_id => 4, :language_id => 1, :title => 'Become content partner')
    TranslatedContactSubject.create(:contact_subject_id => 5, :language_id => 1, :title => 'Content partner support')
    TranslatedContactSubject.create(:contact_subject_id => 6, :language_id => 1, :title => 'Curator support')
    TranslatedContactSubject.create(:contact_subject_id => 7, :language_id => 1, :title => 'Make a correction (spelling and grammar, images, information)')
    TranslatedContactSubject.create(:contact_subject_id => 8, :language_id => 1, :title => 'Images, videos, sounds')
    TranslatedContactSubject.create(:contact_subject_id => 9, :language_id => 1, :title => 'Media requests (interviews, press inquiries, logo requests)')
    TranslatedContactSubject.create(:contact_subject_id => 10, :language_id => 1, :title => 'Make a financial donation')
  end

  def self.down
    ContactSubject.delete_all
    TranslatedContactSubject.delete_all
  end
end
