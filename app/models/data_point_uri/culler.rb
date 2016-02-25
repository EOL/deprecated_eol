class DataPointUri < ActiveRecord::Base
  class Culler
    def self.cull
      culled = 0
      batch_size = 1000 # 10_000 was too high (query broke)
      last = DataPointUri.maximum(:id)
      low = DataPointUri.minimum(:id)
      high = low + batch_size
      # Yes, we might be selecting higher than last, but it doesn't matter.
      while high <= last
        puts "Processing ids #{low} - #{high}:"
        uris = DataPointUri.where(["id > ? AND id < ?", low, high]).pluck(:uri)
        # NOTE: there is nothing like { ?data_point_uri a <class> }, but every
        # DPURI _does_ have a eol:measurementOfTaxon. So I'm using that.
        traits = begin
          results = EOL::Sparql.connection.query(
            "SELECT DISTINCT ?uri { ?uri dwc:occurrenceID ?o . "\
            "FILTER (?uri IN (<#{uris.join(">, <")}>)) }")
          Set.new(results.map { |t| t[:uri].to_s })
        rescue EOL::Exceptions::SparqlDataEmpty => e
          puts "  No URIs exist in Sparql for this batch!"
          Set.new
        end
        uriset = Set.new(uris)
        diff = (Set.new(uris) - traits).to_a
        if diff.count > 0
          puts "  Need to delete #{diff.count} DPURIs..."
          count = DataPointUri.where(uri: diff).delete_all
          culled += count
          puts "  Deleted #{count} (running total: #{culled})."
        else
          puts "  Nothing to delete."
        end
        low += batch_size
        high += batch_size
      end
      puts "Completed. Deleted #{culled} unused data point URIs."
    end
  end
end
