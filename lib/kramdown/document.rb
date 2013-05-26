require 'kramdown'

module Kramdown
  class Document

    def metadata
      # this isn't very good - should really recurse the tree nodes but i haven't worked
      # out how to break cleanly from nested ruby iterators yet.
      @root.children.reduce({}) do |meta, node|
        # stop when we find the header
        if (node.type == :header)
          meta[:title] = node.options[:raw_text]
          break meta
        end
        # process text nodes before the header as metadata attributes
        node.children.select { |c| c.type == :text }.each do |text|
          key, value = text.value.split(':').map { |s| s.strip.downcase }
          case key
          when 'date', 'updated'
            meta[key.to_sym] = Date.parse(value.strip)
          when 'tags'
            meta[:tags] = value.split(',').collect { |tag| tag.strip }
          end
        end
        meta
      end
    end

    def extract_metadata!
      meta = metadata
      @root.children = @root.children.drop_while { |c| c.type != :header }
      meta
    end

  end
end