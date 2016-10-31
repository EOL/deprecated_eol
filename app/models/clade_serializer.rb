class CladeSerializer
  class << self
    # e.g.: CladeSerializer.store_clade_starting_from(7662) => Carnivora
    # e.g.: CladeSerializer.store_clade_starting_from(7665) => Procyonidae (smaller)

    def store_clade_starting_from(pid)
      batch_size = 100
      file_name = Rails.root.join("public", "store-clade-#{pid}.json").to_s
      EOL.log("Storing clade...", prefix: "{")
      File.open(file_name, "wb") do |file|
        file.write("[")
        index = 0
        clade_page = nil
        TaxonConceptsFlattened.descendants_of(pid).find_each(batch_size: batch_size) do |descendant_page|
          if clade_page
            file.write(",\n")
            file.write(clade_page)
          end
          clade_page = JSON.pretty_generate(PageSerializer.get_page_data(descendant_page[:taxon_concept_id]))
        end
        file.write(clade_page + "\n") if clade_page
        file.write("]\n")
      end
      File.chmod(0644, file_name)
      EOL.log("Done storing clade: #{file_name}", prefix: "{")
    end
  end
end
