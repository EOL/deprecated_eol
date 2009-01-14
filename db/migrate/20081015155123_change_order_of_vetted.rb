class ChangeOrderOfVetted < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    Vetted.delete_all
    Vetted.connection.execute("ALTER TABLE vetted AUTO_INCREMENT = 1") # Back where we started, here we go 'round again...
    Vetted.create(:label => 'Untrusted')
    Vetted.create(:label => 'Trusted')
    unknown = Vetted.create(:label => 'Unknown')
    Vetted.connection.execute("UPDATE vetted SET id=0 WHERE id=#{unknown.id}") # gotta get that ID to 0
  end

  def self.down
    Vetted.delete_all
    Vetted.connection.execute("ALTER TABLE vetted AUTO_INCREMENT = 1") # Back where we started, here we go 'round again...
    Vetted.create(:label => 'Trusted')
    Vetted.create(:label => 'Unknown')
    untrusted = Vetted.create(:label => 'Untrusted')
    Vetted.connection.execute("UPDATE vetted SET id=0 WHERE id=#{untrusted.id}") # gotta get that ID to 0
  end
end
