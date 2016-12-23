require 'action_view/digestor'
require 'action_view/lookup_context'

module ActionView
  class Digestor
    @cache = Concurrent::Map.new

    module PerExecutionDigestCacheExpiry
      def self.before(target)
        ActionView::LookupContext::DetailsKey.clear
        Digestor.clear_cache
      end
    end

    class << self
      attr_reader :cache

      def clear_cache
        cache.clear
      end

      def digest(name:, finder:, dependencies: [])
        dependencies ||= []
        cache_key = [
          finder.details_key.hash,
          name,
          finder.rendered_format,
          dependencies,
        ].flatten.compact.join(".")

        # this is a correctly done double-checked locking idiom
        # (Concurrent::Map's lookups have volatile semantics)
        cache[cache_key] || @digest_mutex.synchronize do
          cache.fetch(cache_key) do # re-check under lock
            partial = name.include?("/_")
            root = tree(name, finder, partial)
            dependencies.each do |injected_dep|
              root.children << Injected.new(injected_dep, nil, nil)
            end
            cache[cache_key] = root.digest(finder)
          end
        end
      end
    end

    class Node
      def dependency_digest(finder, stack)
        children.map do |node|
          if stack.include?(node)
            false
          else
            Digestor.cache[node.name] ||= begin
              stack.push node
              node.digest(finder, stack).tap { stack.pop }
            end
          end
        end.join("-")
      end
    end
  end

  class LookupContext
    class DetailsKey #:nodoc:
      @store = Concurrent::Map.new

      # Make hash uniq.
      alias_method :hash, :object_id

      def self.get(details)
        if details[:formats]
          details = details.dup
          details[:formats] &= Template::Types.symbols
        end
        @store[details] ||= new
      end
    end
  end
end

puts 'patched'
