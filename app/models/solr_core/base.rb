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
      reconnect
    end

    def reconnect
      # TODO: make this timeout dynamic. We don't really want production waiting
      # this long! This was meant for publishing tasks.
      timeout = 15.minutes.to_i
      @connection = RSolr.connect(url: "#{$SOLR_SERVER}#{@core}",
        read_timeout: timeout, open_timeout: timeout, retry_503: 3,
        retry_after_limit: timeout)
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
      response = paginate_with_timeout(page, per_page, options.merge(q: q))
      unless response["responseHeader"]["status"] == 0
        raise "Solr error! #{response["responseHeader"]}"
      end
      response
    end

    def paginate_with_timeout(page, per_page, params)
      willing_to_try = 5
      while willing_to_try > 0
        begin
          connection.paginate(page, per_page, "select", params: params)
          willing_to_try = 0
        rescue Timeout::Error => e
          EOL.log("SOLR TIMEOUT: pg#{page}(#{per_page}) q: #{params[:q]}",
            prefix: "!")
          wait_for_recovery(0)
          willing_to_try -= 1
          if willing_to_try > 0
            EOL.log("Solr recovered; retrying #{willing_to_try} times...")
          else
            EOL.log("I GIVE UP!")
            raise e
          end
        end
      end
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
      response = select_with_timeout(params)
      unless response["responseHeader"]["status"] == 0
        raise "Solr error! #{response["responseHeader"]}"
      end
      response
    end

    def select_with_timeout(params)
      begin
        connection.select(params: params)
      rescue Timeout::Error => e
        EOL.log("SOLR TIMEOUT: q: #{params[:q]}", prefix: "!")
        wait_for_recovery(0)
        EOL.log("Solr appears to have recovered; retrying...")
        connection.select(params: params)
      end
    end

    def wait_for_recovery(attempts)
      attempts ||= 0
      begin
        # I want to see that it's STABLE and up...
        try_recovery
        sleep(1)
        try_recovery
        sleep(1)
        try_recovery
      rescue => e
        EOL.log("Solr still down (attempt #{attempts}), waiting...")
        attempts += 1
        raise(e) if attempts >= 56
        sleep(attempts * 0.25)
        wait_for_recovery(attempts)
      end
    end

    def try_recovery
      reconnect
      paginate("*:*", per_page: 1)
    end
  end
end
