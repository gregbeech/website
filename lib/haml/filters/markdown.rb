module Haml::Filters

  remove_filter("Markdown")

  module Markdown
    include Haml::Filters::Base

    def render(text)
      Kramdown::Document.new(text).to_html
    end

  end

end