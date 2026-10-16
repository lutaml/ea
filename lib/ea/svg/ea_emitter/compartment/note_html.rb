# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Splits a note body into paragraphs. A body with HTML markup is
        # shown by EA as plain text: tags are dropped, entities decoded,
        # `<ul>`/`</ul>` lines take no row, and each `<li>` becomes a
        # "- " line stacked directly under the previous text or item
        # (`tight`) instead of leaving the blank row between paragraphs.
        module NoteHtml
          Paragraph = Struct.new(:text, :tight)

          TAG = %r{</?(?:ul|ol|li|b|i|u|p|br|strong|em)\b[^>]*>}i
          LINE_BREAK = /<br\b[^>]*>/i
          LIST_WRAPPER = %r{\A</?(?:ul|ol)>\z}i
          LIST_ITEM = %r{\A<li>(.*)</li>\z}i
          ENTITIES = { "&lt;" => "<", "&gt;" => ">", "&amp;" => "&", "&quot;" => '"' }.freeze

          module_function

          def paragraphs(body)
            text = body.to_s
            return plain(text) unless text.match?(TAG)

            entries = html_lines(text)
            entries.each_with_index.map do |(line, _item, broken), index|
              Paragraph.new(line, broken || entries[index + 1]&.at(1) || false)
            end
          end

          def plain(text)
            text.split(/\n/).reject { |line| line.strip.empty? }.map { |line| Paragraph.new(line, false) }
          end

          def html_lines(text)
            text.split(/\r?\n/).flat_map do |raw|
              line = raw.strip
              next [] if line.empty? || line.match?(LIST_WRAPPER)

              item = line.match(LIST_ITEM)
              item ? broken_lines(item[1], "- ") : broken_lines(line, "")
            end
          end

          # Entries are [text, starts_item, broken]. `<br>` ends a line
          # without the blank row a new paragraph gets, so every segment
          # but the last is `broken` (tight). Only the first segment
          # carries the list bullet.
          def broken_lines(line, bullet)
            segments = line.split(LINE_BREAK).map { |segment| clean(segment) }.reject(&:empty?)
            segments.each_with_index.map do |segment, index|
              first = index.zero?
              [first ? "#{bullet}#{segment}" : segment, first && !bullet.empty?, index < segments.size - 1]
            end
          end

          def clean(line)
            line.gsub(TAG, "").gsub(/&(?:lt|gt|amp|quot);/, ENTITIES).squeeze(" ").strip
          end
        end
      end
    end
  end
end
