require 'json_like'
require 'multi_json'
module JsonLike
  module RSpec

    module MatchesMany
      def matches_many?
        true
      end
    end

    module MatchesOne
      def matches_many?
        false
      end
    end

    class SimpleMatcher < Struct.new(:expected)
      include MatchesOne
      attr :actual
      def matches?( actual )
        expected == (@actual = actual)
      end
      def failure_message_for_should
        "\nexpected: #{expected.inspect}\n     got: #{actual.inspect}\n\n(compared using ==)\n"
      end

      def failure_message_for_should_not
        "\nexpected: value != #{expected.inspect}\n     got: #{actual.inspect}\n\n(compared using ==)\n"
      end
    end

    class UnorderedHashMatcher < Struct.new(:keys, :matchers)

      include MatchesOne
      def initialize( keys = {}, rest = [] )
        super
      end

      def matches?( actual )
        if !actual.kind_of? Hash
          @error = "\nexpected: an object\n     got: #{actual.inspect}\n"
          return false
        end
        keys.each do | key, matcher |

        end
      end

      def failure_message_for_should

      end

    end

    class ArrayMatcher < Struct.new(:values)
      include MatchesOne
      def initialize( values = [] )
        super
      end

      class MatcherEnumerator
        Submatcher = Struct.new(:multiple, :single)
        class Empty
          def matches?( actual )
            (@actual = actual.size) == 0
          end
          def failure_message_for_should
            "\nexpected: no more items\n     got: #{@actual} more\n"
          end
        end
        class OnlyOne < Submatcher
          def errors( enum )
            v = enum.next
            a = []
            a << [single.failure_message_for_should, v] unless single.matches?(v)
            return a
          rescue StopIteration
            return [["\nexpected: more items\n     got: none\n", nil]]
          end
        end
        class OnlyMultiple < Submatcher
          def errors( enum )
            rest = []
            begin
              loop do
                rest << enum.next
              end
            rescue StopIteration
            end
            a = []
            multiple.each do |mul|
              a << [mul.failure_message_for_should, rest] unless mul.matches?(rest)
            end
            return a
          end
        end
        class Both < Submatcher
          def errors( enum )
            rest = []
            error_tail = []
            matched = false
            loop do
              begin
                val = enum.next
                break if single.matches?(val)
                matched = true
                rest << val
              rescue StopIteration
                if matched
                  error_tail << [single.failure_message_for_should, val]
                else
                  error_tail << ["\nexpected: more items\n     got: none\n", nil]
                end
                break
              end
            end
            a = []
            multiple.each do |mul|
              a << [mul.failure_message_for_should, rest] unless mul.matches?(mul)
            end
            return a + error_tail
          end
        end
        def initialize(matchers)
          @matchers = matchers
        end
        def each
          stack = []
          @matchers.each do |m|
            if m.matches_many?
              stack << m
            elsif stack.any?
              yield Both.new(stack, m)
              stack = []
            else
              yield OnlyOne.new(nil, m)
            end
          end
          if stack.any?
            yield OnlyMultiple.new(stack, nil)
          else
            yield OnlyMultiple.new([Empty.new], nil)
          end
          return self
        end
      end

      def matches?( target )
        if target.kind_of? Array
          me = MatcherEnumerator.new( values )
          te = target.to_enum
          errors = []
          me.each do | matcher |
            errors << matcher.errors( te )
          end
          @errors = errors.flatten(1)
          @errors.none?
        else
          @errors = [["\nexpected: an array\n     got: #{target.inspect}\n"]]
          false
        end
      end

      def failure_message_for_should
        @errors.map{|e| e[0] }.join
      end
    end

    class Ellipsis
      include MatchesMany
      def matches?( target )
        true
      end
    end

    class Transform < Parslet::Transform

      rule( object: subtree(:entries) ){
        m = UnorderedHashMatcher.new
        entries.each do |e|
          if e[:matcher]
            m.matchers << e[:matcher]
          else
            m.keys[ e[:key] ] = e[:value]
          end
        end
        m
      }

      rule( entry: subtree(:value) ){
        value
      }

      rule( array: subtree(:entries) ){
        ArrayMatcher.new( entries )
      }

      rule( literal: simple(:value) ){
        value.to_s
      }

      rule( number: simple(:value) ){
        value.to_s.include?('.') ? value.to_f : value.to_i
      }

      rule( string: simple(:value) ){
        value.to_s[1..-2]
      }

      rule( ellipsis: simple(:value) ){
        Ellipsis.new
      }

      rule( atom: simple(:value) ){
        SimpleMatcher.new(value)
      }

    end

    class Matcher

      def initialize( inner )
        @inner = inner
      end

      def matches?( json ) 
        parsed = MultiJson.load(json)
        @inner.matches?( parsed )
      end

      def failure_message_for_should
        @inner.failure_message_for_should
      end

    end

    def self.transform( tree )
      Transform.new.apply( tree )
    end

    def self.matcher( json_like )
      Matcher.new( transform( JsonLike::Parser.new.parse( json_like ) ) )
    end

  end
end
