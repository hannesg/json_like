module JsonLike; class Diff

  class Line < String
    attr :indent
    def initialize( str, indent = 0)
      super(str)
      @indent = indent
    end
  end

  class Context < Line
  end

  class Missing < Line
  end

  class Redundant < Line
  end

  module Linearizer

    def self.linearize(what, indent = 0, current = Context )
      case what
      when ::Array then
        if what.size == 0
          return [ current.new('[]', indent) ]
        end
        *items, last = what.map{|e| 
          linearize(e, indent + 1, current)
        }
        [ current.new("[", indent),
          *items.map{|e| e.last << ',' }.flatten(1),
          *last,
          current.new("]", indent) ]
      when ::Hash then
        *items, last = what.map{|k,v|
          lines = linearize(v, indent + 2, current)
          lines[0] = lines[0].class.new(k+': '+lines[0],indent + 1)
          lines
        }
        [ current.new("{", indent),
          *items.map{|e| e.last << ',' }.flatten(1),
          *last,
          current.new("}", indent) ]
      when ::String then
        what.inspect.split("\n").map{|str| current.new(str, indent) }
      when Numeric, TrueClass, FalseClass, NilClass then
        [ current.new(what.inspect, indent) ]
      else
        if what.respond_to?(:linearize)
          what.linearize( indent, current )
        else
          raise ArgumentError, "Cannot linearize #{what.inspect}"
        end
      end
    end

  end

  module SimpleFormatter
    def self.prefix( lin )
      case( lin )
      when Missing   then '-- '
      when Redundant then '++ '
      else                '   '
      end
    end
    def self.format( linearized )
      linearized.map{|lin|
        prefix(lin) + ('  '*lin.indent) + lin
      }.join("\n")
    end
  end

  class Hash < Diff
    Insert = Struct.new(:item)
    class Insert
      def linearize( indent = 0 )
        Linearizer.linearize(item, indent, Missing)
      end
    end
    Delete = Struct.new(:item)
    class Delete
      def linearize( indent = 0 )
        Linearizer.linearize(item, indent, Redundant)
      end
    end
    Change = Struct.new(:diff)
    class Change
      def linearize( indent = 0 )
        diff.linearize(indent)
      end
    end

    attr :changes, :to

    def initialize( to )
      @to = to
      @changes = {}
    end

    def redundant( key )
      @changes[key] = Delete.new(@to[key])
      return self
    end

    def missing( key, item )
      @changes[key] = Insert.new(item)
      return self
    end

    def wrong( key, diff )
      @changes[key] = Change.new(diff)
      return self
    end

    def linearize( indent = 0)
      result = []
      return result if changes.none?
      i = indent + 1
      keys = (to.keys | changes.keys).sort
      chunks = keys.chunk{|key| @changes.key?(key) }
      chunks.each do |is_changed, keys|
        if is_changed
          keys.each do |key|
            lin = changes[key].linearize( i + 1 )
            result.push( insert_key(key, lin) )
          end
        else
          result.push( insert_key keys.first,  Linearizer.linearize( to[keys.first], i + 1 ) )
          if keys.size > 2
            result.push( [Context.new('...', i + 1)] )
          end
          if keys.size > 1
            result.push( insert_key keys.first, Linearizer.linearize( to[keys.last], i + 1 ) )
          end
        end
      end
      *head, tail = result
      head.each do |item|
        item.last << ','
      end
      return [Context.new('{', indent)] + head.flatten(1) + tail + [Context.new('}',indent)]
    end

    def insert_key( key, lin )
      lin[0] = lin[0].class.new(key + ': ' + lin[0], lin[0].indent - 1)
      return lin
    end
  end

  class Array < Diff
    Insert = Struct.new(:position, :items)
    class Insert
      def linearize( indent = 0 )
        items.map{|item|
          Linearizer.linearize(item, indent, Missing)
        }
      end
      def size
        0
      end
    end
    Delete = Struct.new(:position, :item)
    class Delete
      def linearize( indent = 0 )
        lines = Linearizer.linearize(item, indent, Redundant)
        [lines]
      end
      def size
        1
      end
    end
    Change = Struct.new(:position, :diff)
    class Change
      def linearize( indent = 0 )
        lines = diff.linearize(indent)
        [lines]
      end
      def size
        1
      end
    end

    attr :changes, :to

    def initialize( to, *args )
      @to = to
      @changes = args
    end

    def redundant( i )
      @changes << Delete.new(i, @to[i])
      return self
    end

    def missing( i, item, *items )
      @changes << Insert.new(i, [item] + items)
      return self
    end

    def wrong( i, diff )
      @changes << Change.new( i , diff )
      return self
    end

    def linearize( indent = 0)
      result = []
      return result if changes.none?
      i = indent + 1
      index = -1
      changes.sort_by(&:position).each do |change|
        result.push( *context( i, index, change.position ) )
        result.push( *change.linearize( i ) )
        index = change.position + change.size - 1
      end
      result.push( *context( i, index, to.size) )
      *head, tail = result
      head.each do |item|
        item.last << ','
      end
      return [Context.new('[', indent)] + head.flatten(1) + tail + [Context.new(']',indent)]
    end

    def context( indent, last, current )
      return [] if last == current
      result = []
      l = last + 1
      if l < current && l < to.size
        result << Linearizer.linearize(to[l], indent)
      end
      c = current - 1
      if c > l && c >= 0 && c < to.size
        result << Linearizer.linearize(to[c], indent)
      end
      return result
    end
  end

  class Simple < Diff

    def initialize( to, new )
      @to = to
      @new = new
    end

    def linearize( indent = 0 )
      Linearizer.linearize( @to , indent, Redundant ) +
      Linearizer.linearize( @new , indent, Missing )
    end

  end

  class String < Diff

  end

end ; end
