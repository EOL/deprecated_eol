
namespace :initial_sponsors do

  desc 'Add initial sponsors to DB'
  task :add_initial_sponsors => :environment do
    InstitutionalSponsor.create(name: "Atlas of Living Australia", logo_url: Rails.configuration.partner_logos+"ala.jpg", url: "http://www.ala.org.au/", active: true)
    InstitutionalSponsor.create(name: "Bibliotheca Alexandrina", logo_url: Rails.configuration.partner_logos + "bib_alex.jpg", url: "http://www.bibalex.org/", active: true)
    InstitutionalSponsor.create(name: "CONABIO", logo_url: Rails.configuration.partner_logos + "conabio.jpg" , url: "http://www.conabio.gob.mx/", active: true)
    InstitutionalSponsor.create(name: "Harvard University", logo_url: Rails.configuration.partner_logos + "mcz.jpg", url: "http://www.harvard.edu/", active: true)
    InstitutionalSponsor.create(name: "Marine Biological Laboratory", logo_url: Rails.configuration.partner_logos + "mbl.jpg", url: "http://www.mbl.edu/", active: true)
    InstitutionalSponsor.create(name: "Smithsonian Institution", logo_url: Rails.configuration.partner_logos + "nmnh.jpg", url: "http://www.si.edu/", active: true)
  end
end
