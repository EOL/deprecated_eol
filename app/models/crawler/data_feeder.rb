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
      name
    end

    # NOTE: inefficient to open and close the file for every taxon... but
    # this allows us to see partial results sooner, and we don't mind the
    # additional pause (because our queries slow down the site):
    def add_json(name, json)
      file = File.open(name, "r+")
      begin
        EOL.log("TODO remove me - add_json open")
        pos_stack = [0, 0, 0]
        content_stack = ["", "", ""]
        file.each do |line|
          unless file.eof?
            pos_stack.push(file.pos)
            pos_stack.shift
            content_stack.push(line)
            content_stack.shift
          end
        end
        file.seek(pos_stack.first, IO::SEEK_SET)
        file.puts("#{content_stack.first.chomp},")
        formatted = JSON.pretty_generate(json).gsub(/^/m, "    ")
        file.puts(formatted)
        file.puts(data_feed_closing)
        EOL.log("TODO remove me - add_json closing, size")
        formatted.size
      ensure
        EOL.log("TODO remove me - add_json close")
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
