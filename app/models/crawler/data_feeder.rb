class Crawler::DataFeeder
  class << self
    def filename(options)
      Rails.root.join("public",
        "traitbank-#{options["from"]}-#{options["to"]}.jsonld").to_s
    end

    def create(options)
      name = filename(options)
      File.unlink(name) if File.exist?(name)
      File.open(name, "a") do |f|
        f.puts(data_feed_opening)
        f.puts(data_feed_closing)
      end
    end

    # NOTE: inefficient to open and close the file for every taxon... but
    # this allows us to see partial results sooner, and we don't mind the
    # additional pause (because our queries slow down the site):
    def add_json(name, json)
      file = File.open(name, "r+")
      begin
        last_line = 0
        prev_line = 0
        file.each do |_|
          unless file.eof?
            prev_line = last_line unless last_line == 0
            last_line = file.pos
          end
        end
        file.seek(prev_line, IO::SEEK_SET)
        file.puts(JSON.pretty_generate(json).gsub(/^/m, "      "))
        file.puts(data_feed_closing)
      ensure
        file.close
      end
    end

    def close(name)
      File.open(name, "a") { |f| f.puts(data_feed_closing) }
    end

    def data_feed_opening
      context = {}
      KnownUri.show_in_gui.each do |uri|
        context[uri.name] = uri.uri
      end
      more = {}
      TraitBank::JsonLd.add_default_context(more)
      context.merge!(more["@context"])
      # NOTE: this is an awkard and sloppy way to do a multiline string, sorry:
      %Q%{
        "@context": #{JSON.pretty_generate(context).gsub(/^/m, "      ")},
        "@type": "DataFeed",
        "name": "Company directory",
        "dateModified": "#{Date.today}",
        "dataFeedElement": [
      %.gsub(/^      /m, "")
    end

    def data_feed_closing
      "  ]\n}\n"
    end
  end
end
