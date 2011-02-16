# The only change is to append proxy_options to *args so the named_scope options like
# :select and :include are passed to the find function

module ActiveRecord
  module NamedScope
    class Scope
      private
      def method_missing(method, *args, &block)
        if scopes.include?(method)
          scopes[method].call(self, *args)
        else
          with_scope({:find => proxy_options, :create => proxy_options[:conditions].is_a?(Hash) ?  proxy_options[:conditions] : {}}, :reverse_merge) do
            method = :new if method == :build
            if current_scoped_methods_when_defined && !scoped_methods.include?(current_scoped_methods_when_defined)
              with_scope current_scoped_methods_when_defined do
                proxy_scope.send(method, *args, &block)
              end
            else
              proxy_scope.send(method, *args << proxy_options, &block)
            end
          end
        end
      end
    end
  end
end
