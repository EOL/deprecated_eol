  class SolrCore
    class Base
    attr_reader :connection

    def self.delete_by_ids(ids)
      solr = self.new
      solr.delete_by_ids(ids)
    end

    def self.optimize
      solr = self.new
      solr.optimize
    end

    def self.reindex_items(items)
      solr = self.new
      solr.reindex_items(items)
    end

    def date(date)
      SolrCore.date(date)
    end

    def string(text)
      SolrCore.string(text)
    end

    # Does NOT delete items by ID beforehand.
    def add_items(items)
      @connection.add(Array(items).map(&:to_hash))
      # TODO: error-checking
      @connection.commit
    end

    def connect(name)
      return if @connection
      @core = name
      # TODO: make this timeout dynamic. We don't really want production waiting
      # this long! This was meant for publishing tasks.
      timeout = 10.minutes.to_i
      @connection = RSolr.connect(url: "#{$SOLR_SERVER}#{name}",
        read_timeout: timeout, open_timeout: timeout)
    end

    def commit
      EOL.log_call
      @connection.commit
    end

    def delete_by_ids(ids)
      ids = Array(ids)
      # NOTE: yes, this call is singular (but can take an array)
      @connection.delete_by_id(ids)
      # TODO: error-checking
      @connection.commit
    end

    def delete(query)
      @connection.delete_by_query(query)
      # TODO: error-checking
      @connection.commit
    end

    def optimize
      EOL.log_call
      response = @connection.update(:data => '<optimize/>')
      EOL.log("Optimizing #{@core} Solr core done: #{response.to_json}",
        prefix: '.')
    end

    def paginate(q, options = {})
      page = options.delete(:page) || 1
      per_page = options.delete(:per_page) || 30
      response = begin
        connection.paginate(page, per_page, "select", params: options.merge(q: q))
      rescue Timeout::Error => e
        EOL.log("SOLR TIMEOUT: page/per: #{page}/#{per_page} ; q: #{q}",
          prefix: "!")
        raise(e)
      end
      unless response["responseHeader"]["status"] == 0
        raise "Solr error! #{response["responseHeader"]}"
      end
      response
    end

    # NOTE: this will NOT work on items with composite primary keys.
    def reindex_items(items)
      items = Array(items)
      delete_by_ids(items.map(&:id))
      begin
        @connection.add(items.map(&:to_hash))
      rescue RSolr::Error::Http => e
        EOL.log("WARNING: Failed to reindex items: #{e.message}", prefix: "!")
      end
      @connection.commit
    end

    # NOTE: returns eval'ed ruby (a hash):
    def select(q, options = {})
      params = options.merge(q: q)
      response = select_with_timeout(params, 0)
      unless response["responseHeader"]["status"] == 0
        raise "Solr error! #{response["responseHeader"]}"
      end
      response
    end

    def select_with_timeout(params, tries)
      begin
        connection.select(params: params)
      rescue Timeout::Error => e
        if tries >= 5
          EOL.log("aborting!")
          raise(e)
        end
        tries += 1
        EOL.log("SOLR TIMEOUT (attempt #{tries}): q: #{q}", prefix: "!")
        sleep(tries * 0.25)
        select_with_timeout(params, tries)
      end
    end
  end
end
