# A class to crawl over all the taxon pages and refresh them in various ways.
class Crawler
  @queue = "crawler"

  class << self
    def enqueue
      Crawler::SiteMapIndex.create
      offset = 0
      limit = 25_000
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

    def get_filename(options)
      Rails.root.join("public",
        "traitbank-#{options["from"]}-#{options["to"]}.jsonld").to_s
    end

    def with_output_file(options, &block)
      filename = get_filename(options)
      File.unlink(filename) if File.exist?(filename)
      File.open(filename, "a") { |f| f.puts(data_feed_opening) }
      yield(filename)
      File.open(filename, "a") { |f| f.puts(data_feed_closing) }
      Crawler::SiteMapIndex.add_file(filename)
    end

    # NOTE: We're NOT adding taxa unless they have traits! This may not be
    # desireable... we might want to know the names and the sameAs's for the
    # page. ...TODO: choose?
    def add_taxon_to_file(filename, concept)
      begin
        pj = PageJson.for(concept.id)
        return unless pj && pj.has_traits?
        # NOTE: inefficient to open and close the file for every taxon... but
        # this allows us to see partial results sooner, and we don't mind the
        # additional pause:
        File.open(filename, "a") do |f|
          f.puts(JSON.pretty_generate(pj.ld).gsub(/^/m, "      "))
        end
      rescue => e
        EOL.log("ERROR on page #{concept.id}:", prefix: "!")
        EOL.log_error(e)
      end
    end

    def data_feed_opening
      context = {}
      KnownUri.show_in_gui.each do |uri|
        context[uri.name] = uri.uri
      end
      more = {}
      TraitBank::JsonLd.add_default_context(more)
      context.merge!(more["@context"])
      %Q%
      {
        "@context": #{JSON.pretty_generate(context).gsub(/^/m, "      ")},
        "@type": "DataFeed",
        "name": "Company directory",
        "dateModified": "#{Date.today}",
        "dataFeedElement": [
      %
    end

    def data_feed_closing
      %Q%
        ]
      }
      %
    end
  end
end
