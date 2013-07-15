require 'parslet'
module JsonLike

  class Parser < Parslet::Parser

    rule(:space)      { match('\s').repeat(1) }
    rule(:space?)     { space.maybe }

    rule(:number){ (match('[0-9]').repeat(1) >> ( str('.') >> match('[0-9]').repeat(1) ).maybe).as(:number) }
    rule(:true){ str('true').as(:true) }
    rule(:false){ str('false').as(:false) }
    rule(:null){ str('null').as(:null) }
    # todo: escaping
    rule(:string){ (str('"') >> match('[^"]').repeat >> str('"')).as(:string) }
    rule(:ellipsis){ str('...').as(:ellipsis) }

    rule(:identifier){ match('[a-zA-Z0-9_]').repeat(1).as(:literal) | string }

    rule(:object_entry){ (identifier.as(:key) >> str(':') >> space? >> value.as(:value)) | ellipsis.as(:matcher) }
    rule(:object){ (str('{') >> space? >> ( object_entry >> space? >> ( str(',') >> space? ).maybe ).repeat >> space? >> str('}')).as(:object) }
    rule(:array){ (str('[') >> space? >> (value.as(:entry) >> space? >> ( str(',') >> space?).maybe ).repeat >> str(']')).as(:array) }

    rule(:atom){ (number | self.true | self.false | null | string ).as(:atom) }
    rule(:value){ atom | object | array | ellipsis }

    rule(:spaced_value){ space? >> value >> space? }
    root(:spaced_value)

  end

end
