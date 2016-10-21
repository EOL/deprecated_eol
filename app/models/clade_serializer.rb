class CladeSerializer
  class << self
    # e.g.: CladeSerializer.store_clade_starting_from(7662)  => Carnivora
    def store_clade_starting_from(pid)
      batch_size = 100
      file_name = Rails.root.join("public", "store-#{pid}-clade.json").to_s
      File.open(file_name, "wb") do |file|
        file.write("[")
        index = 0
        clade_pages = []

        TaxonConceptsFlattened.descendants_of(pid).find_each(batch_size: batch_size) do |descendant_page|
          index += 1

          if index % batch_size == 0
            puts "  #{index}..."
            file.write(clade_pages.join("\n"))
            clade_pages = []
          end

          EOL.log("Serializing #{descendant_page[:taxon_concept_id]}...")
          clade_pages << (PageSerializer.get_page_data(descendant_page[:taxon_concept_id])).to_json
        end
        EOL.log("Done.")

        if !clade_pages.blank?
          file.write(clade_pages.join(",\n"))
        end
        file.write("]\n")
      end
      File.chmod(0644, file_name)
    end
  end
end
