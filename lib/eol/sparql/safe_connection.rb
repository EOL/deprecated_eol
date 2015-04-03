# Handles all "expected" errors with virtuoso, helping keep the site "alive" even if the server is unavailable.
#
# To use this, include or extend your class with this module. (Include for
# instance methods, extend for class methods.) This doesn't *solve* the problem,
# but allows you to return a predictable value, which you can then use to show
# an warning message rather than... well... crashing.
module EOL
  module Sparql
    module SafeConnection

      def bad_connection?
        return false unless @bad_connection
        @bad_connection >= 1.minutes.ago
      end

      def if_connection_fails_return(what, &block)
        return(what) if bad_connection?
        begin
          yield
        rescue Net::HTTP::Persistent::Error, SPARQL::Client::ClientError, EOL::Exceptions::SparqlDataEmpty
          @bad_connection = Time.now
          return(what)
        end
      end

    end
  end
end
