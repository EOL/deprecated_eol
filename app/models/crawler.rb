# A class to crawl over all the taxon pages and refresh them in various ways.
class Crawler
  @queue = "crawler"

  class << self
    def enqueue
      Crawler::SiteMapIndexer.create
      offset = 0
      # GOOG's limit is actually 10MB, which we should check, but this will
      # almost certainly not exceed that!
      limit = 5_000
      ids = [] # Probably superfluous, but want to be safe because of #while
      begin
        ids = TaxonConcept.published.limit(limit).order(:id).offset(offset).pluck(:id)
        Resque.enqueue(Crawler, from: ids.first, to: ids.last)
        offset += limit
      end while ids.size > 0
    end

    def perform(options)
      unless options["from"] && options["to"]
        return EOL.log("Crawler: FAILED... from/to missing: #{options.inspect}",
          prefix: "!")
      end
      EOL.log("Crawler: (#{options["from"]}-#{options["to"]})", prefix: "C")
      taxa = TaxonConcept.published.
               where(["id >= ? AND id <= ?", options["from"], options["to"]])
      with_output_file(options) do |filename|
        count = taxa.count
        taxa.each_with_index do |concept, index|
          EOL.log("#{index}/#{count}: #{concept.id} (#{pj.ld.to_s.size})",
            prefix: ".") if index % 100 == 0
          add_taxon_to_file(filename, concept)
          # Minimize load on production:
          sleep(1)
        end
      end
    end

    def with_output_file(options, &block)
      filename = Crawler::DataFeeder.create(options)
      # TODO: all this File stuff belongs in its own Crawler::DataFeeder class.
      yield(filename)
      Crawler::DataFeeder.close(filename)
      Crawler::SiteMapIndexer.add_sitemap(filename)
    end

    # NOTE: We're NOT adding taxa unless they have traits! This may not be
    # desireable... we might want to know the names and the sameAs's for the
    # page. ...TODO: choose?
    def add_taxon_to_file(filename, concept)
      begin
        pj = PageJson.for(concept.id)
        return unless pj && pj.has_traits?
        Crawler::DataFeeder.add_json(pj.ld)
      rescue => e
        EOL.log("ERROR on page #{concept.id}:", prefix: "!")
        EOL.log_error(e)
      end
    end
  end
end
