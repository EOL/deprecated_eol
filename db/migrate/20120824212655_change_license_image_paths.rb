class ChangeLicenseImagePaths < ActiveRecord::Migration
  def self.up
    License.find_each do |l|
      unless l.logo_url.blank?
        l.update_column(:logo_url, l.logo_url.gsub(/\/images\/licenses\//, ''))
      end
    end
  end

  def self.down
    License.find_each do |l|
      unless l.logo_url.blank?
        l.update_column(:logo_url, '/images/licenses/' + l.logo_url)
      end
    end
  end
end
