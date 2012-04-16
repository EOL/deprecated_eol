class RenameSerbianCyrillicAndLatinLanguages < ActiveRecord::Migration
  def self.up
    execute "UPDATE languages SET iso_639_1 = 'sr-EC' WHERE iso_639_1 = 'sr'"
    execute "UPDATE languages SET iso_639_1 = 'sr-el' WHERE iso_639_1 = 'sr-CS'"
  end

  def self.down
    execute "UPDATE languages SET iso_639_1 = 'sr' WHERE iso_639_1 = 'sr-EC'"
    execute "UPDATE languages SET iso_639_1 = 'sr-CS' WHERE iso_639_1 = 'sr-el'"
  end
end
