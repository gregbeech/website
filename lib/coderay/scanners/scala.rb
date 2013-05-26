### Copyright (c) 2011, Taylor Venable
### All rights reserved.
###
### Redistribution and use in source and binary forms, with or without
### modification, are permitted provided that the following conditions are met:
###
###     * Redistributions of source code must retain the above copyright
###       notice, this list of conditions and the following disclaimer.
###
###     * Redistributions in binary form must reproduce the above copyright
###       notice, this list of conditions and the following disclaimer in the
###       documentation and/or other materials provided with the distribution.
###
### THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
### AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
### IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
### ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
### LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
### CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
### SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
### INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
### CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
### ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
### POSSIBILITY OF SUCH DAMAGE.

# Originally based on the Java scanner,
# although there's not too much of it left by now.

require 'coderay/helpers/file_type'

module CodeRay
  if defined? TCV_LOCAL_TESTING then
    module FileType
      TypeFromExt['scala'] = :scala
    end
  end

module Scanners

  class Scala < Scanner

    # include Streamable
    register_for :scala

    # if defined? TCV_LOCAL_TESTING then
        load 'lib/coderay/scanners/scala/builtin_types.rb'
    # else
    #     helper :builtin_types
    # end

    # from the Scala Language Spec, 2.8 - section 1.1: "Identifiers"

    KEYWORDS = %w[
        case catch do else finally for forSome if import match new
        return throw try while yield
        _ : = => <- <: <% >: # @
    ]

    RESERVED = %w[ class def object package trait type val var ]

    CONSTANTS = %w[ false null true Nil None ]

    MAGIC_VARIABLES = %w[ this super ]

    TYPES = %w[
      boolean byte char class double enum float int interface long
      short void
    ] << '[]'  # because int[] should be highlighted as a type

    DIRECTIVES = %w[
      abstract extends final implicit lazy override private protected
      sealed volatile with
    ]

    IDENT_KIND = WordList.new(:ident).
      add(KEYWORDS, :keyword).
      add(RESERVED, :reserved).
      add(CONSTANTS, :pre_constant).
      add(MAGIC_VARIABLES, :local_variable).
      add(TYPES, :type).
      add(BuiltinTypes::List, :pre_type).
      add(BuiltinTypes::List.select { |builtin| builtin[/(Error|Exception)$/] }, :exception).
      add(DIRECTIVES, :directive)

    ESCAPE = / [bfnrtv\n\\'"] | x[a-fA-F0-9]{1,2} | [0-7]{1,3} /x
    UNICODE_ESCAPE =  / u[a-fA-F0-9]{4} | U[a-fA-F0-9]{8} /x
    STRING_CONTENT_PATTERN = {
      "'" => /[^\\']+/,
      '"' => /[^\\"]+/,
      '/' => /[^\\\/]+/
    }
    IDENT = /[a-zA-Z_][A-Za-z_0-9]*/

    def highlight_import_block_element import
      tokens = []
      if groups = import.match(/([\s]*[^\s]+\s*=>\s*)([^\s]+)(.*)/m) then
        tokens << [groups[1], :content]
        tokens << [groups[2], :include]
        tokens << [groups[3], :content]
      elsif groups = import.match(/([\s]*)([^\s]+)(.*)/m) then
        tokens << [groups[1], :content]
        tokens << [groups[2], :include]
        tokens << [groups[3], :content]
      else
        tokens << [import, :content]
      end
      return tokens
    end

    def scan_tokens tokens, options

      state = :initial
      string_delimiter = nil
      import_clause = type_name_follows = last_token_dot = false

      until eos?

        kind = nil
        match = nil

        case state

        when :initial

          if match = scan(/ \s+ | \\\n /x)
            tokens << [match, :space]
            next

          elsif match = scan(%r!/\*.*?(\*/|\n)!) then
            tokens << [match, :comment]
            if match[-1] == ?\n then
              state = :comment
              comment_nesting_level = 1
            end
            next

          elsif match = scan(%r! // [^\n\\]* (?: \\. [^\n\\]* )*!mx)
            tokens << [match, :comment]
            next

          elsif import_clause && scan(/ #{IDENT} (?: \. #{IDENT} )* /ox)
            kind = :include

          elsif match = scan(/ #{IDENT} | \[\] /ox)
            kind = IDENT_KIND[match]
            if last_token_dot
              kind = :ident
            elsif type_name_follows
              kind = :class
              type_name_follows = false
            else
              if match == 'import' then
                tokens << [match, :keyword]
                state = :import
                next
              elsif match == 'class' || match == 'object' || match == 'type' then
                type_name_follows = true
              end
            end

          elsif scan(/ \.(?!\d) | [,?:()\[\]}] | -- | \+\+ | && | \|\| | \*\*=? | [-+*\/%^~&|<>=!]=? | <<<?=? | >>>?=? /x)
            kind = :operator

          elsif scan(/;/)
            import_clause = false
            kind = :operator

          elsif scan(/\{/)
            type_name_follows = false
            kind = :operator

          elsif check(/[\d.]/)
            if scan(/0[xX][0-9A-Fa-f]+/)
              kind = :hex
            elsif scan(/(?>0[0-7]+)(?![89.eEfF])/)
              kind = :oct
            elsif scan(/\d+[fFdD]|\d*\.\d+(?:[eE][+-]?\d+)?[fFdD]?|\d+[eE][+-]?\d+[fFdD]?/)
              kind = :float
            elsif scan(/\d+[lL]?/)
              kind = :integer
            end

          elsif match = scan(/"""/)
            tokens << [:open, :string]
            tokens << ['"""', :delimiter]
            tokens << [:close, :string]
            string_delimiter = match
            string_raw = false
            state = :string
            next

          elsif match = scan(/["']/)
            tokens << [:open, :string]
            state = :string
            string_delimiter = match
            kind = :delimiter

          else
            getch
            kind = :error

          end

          # END state = :initial

        when :import
          if match = scan_until(/\n|\{/) then
            if match[-1] == ?{ then
              tokens << [match[0 .. -2], :include]
              tokens << ["{", :content]
              state = :import_block
              next
            else
              tokens << [match[0 .. -1], :include]
              state = :initial
              next
            end
          end

          # END state = :import

        when :import_block
          if match = scan_until(/\}/) then
            imports = match[0 .. -2].split(",")
            imports[0 .. -2].each { |import|
              highlight_import_block_element(import).each { |t| tokens << t }
              tokens << [",", :content]
            }
            highlight_import_block_element(imports[-1]).each { |t| tokens << t }
            tokens << ["}", :content]
            state = :initial
            next
          end

          # END state = :import_block

        when :comment
          if match = scan_until(%r!\*/|/\*|\n!) then
            if match[-1] == ?\n then
              tokens << [match[0 .. -2], :comment]
              tokens << ["\n", :content]
            elsif match[-1] == ?/ then
              tokens << [match, :comment]
              comment_nesting_level -= 1
              if comment_nesting_level == 0 then
                state = :initial
              end
            elsif match[-1] == ?* then
              tokens << [match, :comment]
              comment_nesting_level += 1
            end
            next
          end

          # END state = :comment

        when :string
          if string_delimiter == '"""' then
            if match = scan_until(/"""|\n/) then
              if match[-1] == ?\n then
                tokens << [:open, state]
                tokens << [match[0 .. -2], :content]
                tokens << [:close, state]
                tokens << ["\n", :content]
                next
              else
                tokens << [:open, state]
                tokens << [match[0 .. -4], :content]
                tokens << ['"""', :delimiter]
                tokens << [:close, state]
                string_delimiter = nil
                state = :initial
                next
              end
            end
          elsif scan(STRING_CONTENT_PATTERN[string_delimiter])
            kind = :content
          elsif match = scan(/["'\/]/)
            tokens << [match, :delimiter]
            tokens << [:close, state]
            string_delimiter = nil
            state = :initial
            next
          elsif state == :string && (match = scan(/ \\ (?: #{ESCAPE} | #{UNICODE_ESCAPE} ) /mox))
            if string_delimiter == "'" && !(match == "\\\\" || match == "\\'")
              kind = :content
            else
              kind = :char
            end
          elsif scan(/\\./m)
            kind = :content
          elsif scan(/ \\ | $ /x)
            tokens << [:close, state]
            kind = :error
            state = :initial
          else
            raise_inspect "else case \" reached; %p not handled." % peek(1), tokens
          end

          # END state = :string

        else
          raise_inspect 'Unknown state', tokens

        end

        match ||= matched
        raise_inspect('Empty token', tokens) unless match

        last_token_dot = match == '.'

        tokens << [match, kind]

      end

      if state == :string
        tokens << [:close, state]
      end

      tokens
    end

  end

end
end

# vim:set sw=2 ts=2: