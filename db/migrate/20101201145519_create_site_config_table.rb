class CreateSiteConfigTable < ActiveRecord::Migration
  def self.up
    create_table :site_configuration_options do |t|
      t.string :parameter
      t.string :value
      t.timestamps
    end
    add_index :site_configuration_options, :parameter, :unique => true
    SiteConfigurationOption.create(:parameter => 'email_actions_to_curators', :value => 'true')
    SiteConfigurationOption.create(:parameter => 'email_actions_to_curators_address', :value => 'pleary@mbl.edu')
    SiteConfigurationOption.create(:parameter => 'reference_parsing_enabled', :value => nil)
    SiteConfigurationOption.create(:parameter => 'reference_parser_pid', :value => 'pleary@mbl.edu')
    SiteConfigurationOption.create(:parameter => 'reference_parser_endpoint', :value => 'http://refman.eol.org/cgi-bin/refparser.cgi')
  end

  def self.down
    drop_table :site_configuration_options
  end
end
