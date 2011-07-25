n = 10

@collection = Collection.find(2)

Benchmark.bm do |x|

  x.report("Solr size") do
    n.times do
      EOL::Solr::CollectionItems.get_facet_counts(@collection.id)
    end
  end

  x.report("Count") do
    n.times do
      @collection.collection_items.count
    end
  end

end
