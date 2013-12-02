# encoding: utf-8
module CodeRay
  module Scanners
    
    # Simple Scanner for Gherkin (Cucumber).
    # 
    class Gherkin < Scanner

      register_for :gherkin
      file_extension 'feature'
      title 'Gherkin'
      
      def scan_tokens(tokens, options)
        in_string = false
        until eos?
          match = scan(/.*\n?/)
          if match =~ /^(\s*)(Feature:|Scenario:|Scenario Outline:|Background:|Examples:)(.*)$/
            tokens.text_token $1, :output
            tokens.text_token $2, :keyword
            tokens.text_token "#{$3}\n", :string
          elsif match =~ /^(\s*)(Given |When |Then |And |But |\* )(.*)$/
            tokens.text_token $1, :output
            tokens.text_token $2, :keyword
            $3.split(/"/).each.with_index do |text, index|
              if index.even?
                tokens.text_token text, :output
              else
                tokens.text_token "\"#{text}\"", :string
              end
            end
            tokens.text_token "\n", :output
          elsif match =~ /^\s*#/
            tokens.text_token match, :comment
          elsif match =~ /^\s*@/
            tokens.text_token match, :label
          elsif match =~ /^\s*"""/
            in_string = !in_string
            tokens.text_token match, :string
          elsif match =~ /^\s*\|/
            tokens.text_token match, :keyword
          else
            tokens.text_token match, in_string ? :string : :output
          end
        end
        tokens
      end
      
    end
    
  end
end