#!/bin/env ruby

Jekyll::Hooks.register :site, :pre_render do |site|
    puts "Adding more pseudo-ts..."
    require "rouge"

    class PseudoTS < Rouge::RegexLexer
        title 'PseudoTS'
        aliases 'pseudo-ts'

        ws = %r((?:\s|#.*?\n|/[*].*?[*]/)+)

        keywords = %w(
            let var
            namespace interface class type fn
            override open final extends implements
            this
            new

            if else
            while loop break continue
            jump label return
            switch
        )

        id = /[[:alpha:]_][[:word:]\-\/]*/
        const_name = /[[:upper:]][[:upper:][:digit:]_]*\b/
        type_name = /[[:upper:]][[:word:]\-\/]*\b/

        state :root do
            rule %r/[^\S\n]+/, Text
            rule %r/#(\s.*)?$/, Comment::Single
            rule %r/\b(#{keywords.join('|')})\b/, Keyword
            rule type_name, Keyword::Type
            rule const_name, Name::Constant
            rule %r/\$?#{id}/, Name
            rule %r/"(\\\\|\\"|[^"])*"/, Str
            rule %r/'(\\\\|\\'|[^'])*"/, Str
            rule %r/(\.)(#{id})/ do
                groups Operator, Name::Attribute
            end
            rule %r/[\(\)\{\};\.=,:]/, Operator
        end
    end
end
