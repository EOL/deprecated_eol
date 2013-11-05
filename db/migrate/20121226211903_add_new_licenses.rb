class AddNewLicenses < ActiveRecord::Migration
  def self.up
    cc_zero = License.create(:title => 'cc-zero 1.0', :source_url => 'http://creativecommons.org/publicdomain/zero/1.0/', :version => '1.0',
      :logo_url => 'cc_zero_small.png', :show_to_content_partners => 1)
    TranslatedLicense.create(:license => cc_zero, :language => Language.default, :description => 'Public Domain')

    no_known_restrictions = License.create(:title => 'no known copyright restrictions', :logo_url => '', :source_url => 'http://www.flickr.com/commons/usage/',
      :version => '', :show_to_content_partners => 1)
    TranslatedLicense.create(:license => no_known_restrictions, :language => Language.default, :description => 'No known copyright restrictions')
  end

  def self.down
    if cc_zero = License.find_by_title('cc-zero 1.0')
      cc_zero.translations.each{ |tr| tr.destroy }
      cc_zero.destroy
    end

    if no_known_restrictions = License.find_by_title('no known copyright restrictions')
      no_known_restrictions.translations.each{ |tr| tr.destroy }
      no_known_restrictions.destroy
    end
  end
end
