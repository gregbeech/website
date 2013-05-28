module CodeRay
  module Scanners

    # Scanner for C++.
    # 
    # Aliases: cs, csharp
    #
    # From here: http://www.redmine.org/boards/3/topics/11616.
    class VB < Scanner

      register_for :vb
      file_extension 'vb'
      title 'Visual Basic'
      
      #-- http://www.cppreference.com/wiki/keywords/start       
      KEYWORDS = ["AddHandler", "AddressOf", "Alias",
"And", "AndAlso", "As", "Boolean", "ByRef", "Byte", "ByVal", "Call", "Case", "Catch", "CBool", "CByte",
"CChar", "CDate", "CDec", "CDbl", "Char", "CInt", "Class", "CLng", "CObj", "Const", "Continue", "CSByte",
"CShort", "CSng", "CStr", "CType", "CUInt", "CULng", "CUShort", "Date", "Decimal", "Declare", "Default", "Delegate",
"Dim", "DirectCast", "Do", "Double", "Each", "Else", "ElseIf", "End", "EndIf", "Enum", "Erase", "Error", "Event",
"Exit", "Finally", "For", "Function", "Get", "GetType", "GetXMLNamespace", "Global", "GoSub", "GoTo",
"Handles", "If", "If()", "Implements", "Imports", "Imports", "In", "Inherits", "Integer", "Interface", "Is", "IsNot",
"Let", "Lib", "Like", "Long", "Loop", "Me", "Mod", "Module", "MyBase", "MyClass",
"Namespace", "Narrowing", "New", "Next", "Not", "NotInheritable", "Object", "Of", "On",
"Operator", "Option", "Optional", "Or", "OrElse", "ParamArray", "Partial",
"Property", "RaiseEvent", "ReadOnly", "ReDim", "REM", "RemoveHandler", "Resume",
"Return", "SByte", "Select", "Set", "Short", "Single", "Step", "Stop", "String",
"Structure", "Sub", "SyncLock", "Then", "Throw", "To", "Try", "TryCast", "TypeOf", "Variant", "Wend",
"UInteger", "ULong", "UShort", "Using", "When", "While", "Widening", "With", "WithEvents", "WriteOnly", "Xor", "#Const",
"#Else", "#ElseIf", "#End", "#If", "=", "&", "&=", "*", "*=", "/", "/=", "\\", "\\=", "^", "^=", "+", "+=", "-", "-=",
">>", ">>=", "<<", "<<="       ]  # :nodoc:

      PREDEFINED_TYPES = [
        'bool', 'byte', 'char', 'decimal', 'double', 'float', 'int', 'long',
        'object', 'sbyte', 'short', 'string', 'uint', 'ulong', 'ushort'
      ]  # :nodoc:
      PREDEFINED_CONSTANTS = [
        "False", "Nothing", "True"
      ]  # :nodoc:
      PREDEFINED_VARIABLES = [
        # 'base', 'this'
      ]  # :nodoc:
      DIRECTIVES = [
        "Friend", "MustInherit", "MustOverride", "NotOverridable",
        "Overloads", "Overridable", "Overrides", "Private", "Protected", "Public", "Shadows", "Shared", "Static", 
        
      ]  # :nodoc:
      
      IDENT_KIND = WordList.new(:ident).
        add(KEYWORDS, :keyword).
        add(PREDEFINED_TYPES, :predefined_type).
        add(PREDEFINED_VARIABLES, :local_variable).
        add(DIRECTIVES, :directive).
        add(PREDEFINED_CONSTANTS, :predefined_constant)  # :nodoc:

      ESCAPE = / [rbfntv\n\\'"] | x[a-fA-F0-9]{1,2} | [0-7]{1,3} /x  # :nodoc:
      UNICODE_ESCAPE =  / u[a-fA-F0-9]{4} | U[a-fA-F0-9]{8} /x  # :nodoc:
      
    protected
      
      def scan_tokens encoder, options

        state = :initial
        label_expected = true
        case_expected = false
        label_expected_before_preproc_line = nil
        in_preproc_line = false

        until eos?

          case state

          when :initial

            if match = scan(/ \s+ | \\\n /x)
              if in_preproc_line && match != "\\\n" && match.index(?\n)
                in_preproc_line = false
                label_expected = label_expected_before_preproc_line
              end
              encoder.text_token match, :space

            elsif match = scan(%r! // [^\n\\]* (?: \\. [^\n\\]* )* | /\* (?: .*? \*/ | .* ) !mx)
              encoder.text_token match, :comment

            elsif match = scan(/ \# \s* if \s* 0 /x)
              match << scan_until(/ ^\# (?:elif|else|endif) .*? $ | \z /xm) unless eos?
              encoder.text_token match, :comment

            elsif match = scan(/ [-+*=<>?:;,!&^|()\[\]{}~%]+ | \/=? | \.(?!\d) /x)
              label_expected = match =~ /[;\{\}]/
              if case_expected
                label_expected = true if match == ':'
                case_expected = false
              end
              encoder.text_token match, :operator

            elsif match = scan(/ [A-Za-z_][A-Za-z_0-9]* /x)
              kind = IDENT_KIND[match]
              if kind == :ident && label_expected && !in_preproc_line && scan(/:(?!:)/)
                kind = :label
                match << matched
              else
                label_expected = false
                if kind == :keyword
                  case match
                  when 'class', 'interface', 'struct'
                    state = :class_name_expected
                  when 'case', 'default'
                    case_expected = true
                  end
                end
              end
              encoder.text_token match, kind

            elsif match = scan(/\$/)
              encoder.text_token match, :ident
            
            elsif match = scan(/@?"/)
              encoder.begin_group :string
              state = :string
              encoder.text_token match, :delimiter

            elsif match = scan(/'/)
              encoder.begin_group :char
              state = :char
              encoder.text_token match, :delimiter

            elsif match = scan(/#[ \t]*(\w*)/)
              encoder.text_token match, :preprocessor
              in_preproc_line = true
              label_expected_before_preproc_line = label_expected

            elsif match = scan(/\d+[dDfFmM]|\d*\.\d+(?:[eE][+-]?\d+)?[dDfFmM]?|\d+[eE][+-]?\d+[dDfFmM]?/)
              label_expected = false
              encoder.text_token match, :float

            elsif match = scan(/0[xX][0-9A-Fa-f]+|[0-9]+(([uU][lL])|[lL])?/)
              label_expected = false
              encoder.text_token match, :integer

            else
              encoder.text_token getch, :error

            end

          when :string
            if match = scan(/[^\\"]+/)
              encoder.text_token match, :content
            elsif match = scan(/"/)
              encoder.text_token match, :delimiter
              encoder.end_group :string
              state = :initial
              label_expected = false
            elsif match = scan(/ \\ (?: #{ESCAPE} | #{UNICODE_ESCAPE} ) /mox)
              encoder.text_token match, :char
            elsif match = scan(/ \\ | $ /x)
              encoder.end_group :string
              encoder.text_token match, :error
              state = :initial
              label_expected = false
            else
              raise_inspect "else case \" reached; %p not handled." % peek(1), encoder
            end

          when :char
            if match = scan(/[^\\'']+/)
              encoder.text_token match, :content
            elsif match = scan(/'/)
              encoder.text_token match, :delimiter
              encoder.end_group :char
              state = :initial
              label_expected = false
            elsif match = scan(/ \\ (?: #{ESCAPE} | #{UNICODE_ESCAPE} ) /mox)
              encoder.text_token match, :char
            elsif match = scan(/ \\ | $ /x)
              encoder.end_group :char
              encoder.text_token match, :error
              state = :initial
              label_expected = false
            else
              raise_inspect "else case \" reached; %p not handled." % peek(1), encoder
            end

          when :class_name_expected
            if match = scan(/ [A-Za-z_][A-Za-z_0-9]* /x)
              encoder.text_token match, :class
              state = :initial

            elsif match = scan(/\s+/)
              encoder.text_token match, :space

            else
              encoder.text_token getch, :error
              state = :initial

            end
            
          else
            raise_inspect 'Unknown state', encoder

          end

        end

        if state == :string
          encoder.end_group :string
        end

        encoder
      end

    end

  end
end