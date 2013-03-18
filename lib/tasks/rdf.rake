namespace :rdf do

  desc 'Create Catalogue of Life RDF/XML'
  task :create_col_rdf_xml => :environment do
    EOL::Sparql::ExportCol.as_rdf_xml
  end

  desc 'Create Catalogue of Life N-Tuples'
  task :create_col_tuples => :environment do
    EOL::Sparql::ExportCol.as_turtle
  end

  desc 'load_catalogue_of_life'
  task :load_catalogue_of_life => :environment do
    importer = EOL::Sparql::ImportCol.new()
    importer.begin
  end

  desc 'load_users'
  task :load_users => :environment do
    importer = EOL::Sparql::ImportUsers.new()
    importer.begin
  end

  desc 'load_obis'
  task :load_obis => :environment do
    importer = EOL::Sparql::ImportObis.new()
    importer.begin
  end

  desc 'load_anage'
  task :load_anage => :environment do
    importer = EOL::Sparql::ImportAnage.new()
    importer.begin
  end

  desc 'test'
  task :test => :environment do
    tester = EOL::Sparql::Tester.new
    tester.begin
  end

end
