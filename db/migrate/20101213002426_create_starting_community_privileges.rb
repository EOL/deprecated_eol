class CreateStartingCommunityPrivileges < ActiveRecord::Migration

  def self.up
    EOL::DB::toggle_eol_data_connections(:eol_data)
    if Language.english.nil?
      Language.create(:iso_639_1 => 'en', :iso_639_2 => 'eng', :iso_639_3 => 'eng', :label => 'English', :name => 'English', :sort_order => 1, :source_form => 'English')
    end
    Privilege.create_defaults
    EOL::DB::toggle_eol_data_connections(:eol)
  end

  def self.down
    # Nothing to do.  Deleting all of the privs is NOT desirable; an error is not appropriate.
  end

end
