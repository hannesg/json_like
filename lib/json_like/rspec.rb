require 'json_like'
require 'json_like/diff'
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
      def diff( actual )
        if expected == actual
          return nil
        else
          Diff::Simple.new( actual, expected )
        end
      end
      def linearize( indent = 0, current = Diff::Context )
        Diff::Linearizer.linearize( expected, indent, current )
      end
    end

    class UnorderedHashMatcher < Struct.new(:keys, :matchers)

      include MatchesOne
      def initialize( keys = {}, rest = [] )
        super
      end

      def diff( actual )
        if !actual.kind_of? Hash
          return Diff::Simple.new( actual, self )
        end
        diff = Diff::Hash.new( actual )
        rest = {}
        ( keys.keys | actual.keys ).each do | key |
          if keys.key?( key )
            if !actual.key? key
              diff.missing(key, keys[key])
            else
              d = keys[key].diff(actual[key])
              if d
                diff.wrong(key, d)
              end
            end
          else
            rest[key] = actual[key]
          end
        end
        if matchers.none?
          rest.each do |key, _|
            diff.redundant( key )
          end
        else

        end
        return nil if diff.changes.none?
        return diff
      end

      def linearize( indent = 0, current = Diff::Context )
        inner = keys.sort_by{|k,_| k }.map{|k,v|
          lines = Diff::Linearizer.linearize(v, indent + 2, current)
          lines[0] = lines[0].class.new(k+': '+lines[0],indent + 1)
          lines
        }
        inner += matchers.map{|r| Diff::Linearizer.linearize( r , indent+1, current) }
        *items, last = inner
        [ current.new("{", indent),
          *items.map{|e| e.last << ',' ; e }.flatten(1),
          *last,
          current.new("}", indent) ]
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
          def diff( actual )
            (@actual = actual.size) == 0
          end
        end
        class OnlyOne < Submatcher
          def errors( diff, enum )
            v,i  = enum.next
            d = single.diff( v )
            if d
              diff.wrong( i, d )
            end
          rescue StopIteration
            diff.missing( i || 0, single )
          end
        end
        class OnlyMultiple < Submatcher
          def errors( diff, enum )
            rest = []
            loop do
              rest << enum.next
            end
            #multiple.each do |mul|
            #  a << [mul.failure_message_for_should, rest] unless mul.matches?(rest)
            #end
            #return a
          end
        end
        class Both < Submatcher
          def errors( diff, enum )
            rest = []
            error_tail = []
            last_diff = nil
            last_i = 0
            loop do
              begin
                val, i = enum.next
                last_diff = single.diff( val )
                break if last_diff.nil?
                last_i = i
                rest << val
              rescue StopIteration
                if last_diff
                  diff.wrong( last_i, last_diff )
                else
                  diff.missing( last_i, single.expected )
                end
                break
              end
            end
            #a = []
            #multiple.each do |mul|
            #  a << [mul.failure_message_for_should, rest] unless mul.matches?(mul)
            #end
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

      def linearize( indent = 0, current = Diff::Context )
        return Diff::Linearizer.linearize( values , indent, current)
      end

      def diff( target )
        if target.kind_of? Array
          me = MatcherEnumerator.new( values )
          diff = Diff::Array.new( target )
          te = target.to_enum(:each_with_index)
          me.each do | matcher |
            matcher.errors( diff, te )
          end
          return nil if diff.changes.none?
          diff
        else
          return Diff::Simple.new( target, values )
        end
      end

    end

    class Ellipsis
      include MatchesMany
      def matches?( target )
        true
      end
      def diff( actual )
        return nil
      end
      def linearize( indent = 0, current = Diff::Context )
        [ current.new('...',indent) ]
      end
    end

    class Transform < Parslet::Transform

      rule( object: subtree(:entries) ){
        m = UnorderedHashMatcher.new
        if entries.kind_of? Array
          entries.each do |e|
            if e[:matcher]
              m.matchers << e[:matcher]
            else
              m.keys[ e[:key] ] = e[:value]
            end
          end
        end
        m
      }

      rule( entry: subtree(:value) ){
        value
      }

      rule( array: sequence(:entries) ){
        ArrayMatcher.new( entries )
      }

      rule( array: simple(:_) ){
        ArrayMatcher.new
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

      rule( null: simple(:value) ){
        nil
      }

      rule( false: simple(:value) ){
        false
      }

      rule( true: simple(:value) ){
        true
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
        @diff = @inner.diff( parsed )
        return @diff.nil?
      end

      def failure_message_for_should
        Diff::SimpleFormatter.format @diff.linearize
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
