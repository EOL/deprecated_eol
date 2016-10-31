class CladeSerializer
  class << self
    # e.g.: CladeSerializer.store_clade_starting_from(7662) => Carnivora
    # e.g.: CladeSerializer.store_clade_starting_from(7665) => Procyonidae (smaller)

    def store_clade_starting_from(pid)
      part = 1
      batch_size = 100
      stored = 0
      taxa = TaxonConceptsFlattened.descendants_of(pid)
      batch = []
      EOL.log("CLS: Storing clade starting from Page ID #{pid}...", prefix: "{")

      clade_page = nil
      taxa.find_each(batch_size: batch_size) do |descendant_page|
        batch << JSON.pretty_generate(PageSerializer.get_page_data(descendant_page[:taxon_concept_id]))
        if batch.size >= batch_size
          stored += flush(pid, batch, part += 1)
          batch = []
        end
      end
      EOL.log("CLS: Done (#{stored} pages from Page ID #{pid}).", prefix: "}")
    end

    def flush(pid, batch, part)
      file_name = Rails.root.join("public", "store-clade-#{pid}-part#{part}.json").to_s
      EOL.log("CLS: Flushing #{batch.size} pages into #{file_name}...", prefix: "..")
      File.open(file_name, "wb") do |file|
        file.write("[\n")
        file.write(batch.join(",\n"))
        file.write("\n]\n")
      end
      File.chmod(0644, file_name)
      batch.size
    end
  end
end
