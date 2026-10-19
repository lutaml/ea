# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Splits a note body into paragraphs, one per non-empty source
        # line. Each paragraph stacks directly under the previous one
        # (`gap` 0); every empty source line after it adds one blank row.
        # A body with HTML markup is shown by EA as plain text: tags are
        # dropped, entities decoded, `<ul>`/`</ul>` lines take no row,
        # each `<li>` becomes a "- " line and `<br>` ends a line.
        module NoteHtml
          Paragraph = Struct.new(:text, :gap)

          TAG = %r{</?(?:ul|ol|li|b|i|u|p|br|strong|em)\b[^>]*>}i
          LINE_BREAK = /<br\b[^>]*>/i
          LIST_WRAPPER = %r{\A</?(?:ul|ol)>\z}i
          LIST_ITEM = %r{\A<li>(.*)</li>\z}i
          ENTITIES = { "&lt;" => "<", "&gt;" => ">", "&amp;" => "&", "&quot;" => '"' }.freeze

          module_function

          def paragraphs(body)
            text = body.to_s
            markup = text.match?(TAG)
            lines = text.split(/\r?\n/)
            lines.reject! { |raw| raw.strip.match?(LIST_WRAPPER) } if markup
            lines.each_with_object([]) do |raw, paragraphs|
              raw.strip.empty? ? paragraphs.last&.gap += 1 : paragraphs.concat(line_paragraphs(raw, markup))
            end
          end

          def line_paragraphs(raw, markup)
            markup ? html_lines(raw.strip) : [Paragraph.new(raw, 0)]
          end

          def html_lines(line)
            item = line.match(LIST_ITEM)
            segments = (item ? item[1] : line).split(LINE_BREAK).map { |segment| clean(segment) }.reject(&:empty?)
            segments.each_with_index.map do |segment, index|
              Paragraph.new(item && index.zero? ? "- #{segment}" : segment, 0)
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
