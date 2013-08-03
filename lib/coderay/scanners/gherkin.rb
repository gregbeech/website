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
        until eos?
          match = scan(/.*\n?/)
          if match =~ /^(\s*)(Feature:|Scenario:|Scenario Outline:|Background:|Examples:|Given |When |Then |And |But |\* )(.*)$/
            tokens.text_token $1, :output
            tokens.text_token $2, :keyword
            tokens.text_token "#{$3}\n", :output
          elsif match =~ /^\s*#/
            tokens.text_token match, :comment
          elsif match =~ /^\s*@/
            tokens.text_token match, :string
          elsif match =~ /^\s*"""/
            tokens.text_token match, :keyword
          elsif match =~ /^\s*\|/
            match.scan(/([^\|]*)(\|\s*)/) do |cell, bar|
              tokens.text_token cell, :output
              tokens.text_token bar, :keyword
            end
          else
            tokens.text_token match, :output
          end
        end
        tokens
      end
      
    end
    
  end
end