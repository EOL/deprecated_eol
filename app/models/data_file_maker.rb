class DataFileMaker

  LIMIT = 100

  @queue = 'data'

  def self.perform(args)
    puts "++ DataFileMaker: #{args.values.join(', ')}"
    DataFileMaker.build_csv_from_results(q: args["querystring"], uri: args["attribute"], from: args["from"], to: args["to"],
                                         sort: args["sort"], known_uri: KnownUri.find(args["known_uri_id"]),
                                         language: Language.find(args["language_id"]))
    puts "   ...Done."
  end

  # TODO - really, this should be a separate object with nice methods. Rushing a bit.
  def self.build_csv_from_results(args)
    puts "   #build_csv_from_results"
    # TODO - do nothing if we already have a file...
    # TODO - really, we shouldn't use pagination at all, here.
    results = TaxonData.search(querystring: args[:q], attribute: args[:uri], from: args[:from], to: args[:to],
      sort: args[:sort], per_page: LIMIT) # TODO - if we KEEP pagination, make this value more sane (and put page back in).
    puts "   results = #{results.count}"
    # TODO - handle the case where results are empty.
    rows = []
    results.each do |data_point_uri|
      rows << data_point_uri.to_hash(args[:language])
    end
    puts "   .. made rows"
    col_heads = Set.new
    rows.each do |row|
      col_heads.merge(row.keys)
    end
    puts "   .. made heads (#{col_heads.to_a.join(', ')})"
    path = "something.csv"
    if args[:known_uri]
      path = "#{args[:known_uri].name}.csv" 
      path += "_f#{args[:from]}" unless args[:from].blank?
      path += "-#{args[:to]}" unless args[:to].blank?
      path += "_by_#{args[:sort]}" unless args[:sort].blank?
      # TODO - handle other filename cases as needed
    end
    puts "  -> #{Rails.root.join("public", path)}"
    CSV.open(Rails.root.join("public", path), "wb") do |csv|
      csv << col_heads
      rows.each do |row|
        csv << col_heads.inject([]) { |a, v| a << row[v] } # A little magic to sort the values...
      end
    end
    puts "  .. file created."
  end

end
