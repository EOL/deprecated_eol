module ActiveRetryConnection
  def self.included(base)
    base.class_eval do
      alias_method(:verify!, :verify_with_deferred_retry!)
      alias_method_chain(:execute, :active_retry)
    end
  end

  # verify is called (checkout_and_verify from connection_pool) at the beginning of request cycle
  # no longer calls active? for pinging the database 
  def verify_with_deferred_retry!
    # handle nil @connection for mysql2_adapter
    if @connection.nil?
      reconnect!
    end
    @__retry_ok = true
  end

  def execute_with_active_retry(sql, name = nil)
    # if this is the first sql statement since a verify, it's ok
    # to retry the connection if it's gone away
    retry_ok = @__retry_ok
    @__retry_ok = false

    # do not retry query in a transaction
    if retry_ok && open_transactions > 0
      retry_ok = false
    end

    begin
      return execute_without_active_retry(sql, name)
    rescue ::ActiveRecord::StatementInvalid, ::Mysql::Error => exception
      raise if !(exception.message =~ /(not connected|Can't connect to MySQL|MySQL server has gone away|Lost connection to MySQL server|Packet too large)/i)
      raise unless retry_ok
      retry_ok = false # avoid retry loop; retry exactly once
      reconnect!
      retry
    end
  end
end
