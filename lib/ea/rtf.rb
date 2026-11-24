# frozen_string_literal: true

module Ea
  # Converts EA RTF notes to plain text. Enterprise Architect stores
  # styled documentation as RTF ({\rtf1...}) in t_object.Note,
  # t_attribute.Notes, t_connector.Notes, etc.; plain-text notes are
  # stored as-is. Non-RTF input passes through unchanged.
  module Rtf
    # Destination groups whose entire content is metadata, not text
    DESTINATIONS = %w[
      fonttbl colortbl stylesheet info pict object listtable
      listoverridetable rsidtbl generator mmathpr themedata
      colorschememapping datastore latentstyles wgrformat
    ].freeze

    DEST_START_RX = /\A\{\\(\*)?\\?(?:#{DESTINATIONS.join("|")})\b/
    WORD_RX = /\A\\([a-z]+)(-?\d+)? ?/
    UNICODE_RX = /\A\\u(-?\d+)/

    module_function

    # @param text [String, nil] RTF or plain text
    # @return [String, nil] plain text, or the input for non-RTF
    def to_text(text)
      return text if text.nil? || text.empty?
      return text unless text.lstrip.start_with?("{\\rtf")

      out = +""
      parse_group(text, 0, out, skipping: false)
      out.strip
    end

    # Parse the group starting at text[start] (positioned at "{").
    # @return [Integer] index just past the group's closing brace
    def parse_group(text, start, out, skipping:) # rubocop:disable Metrics/MethodLength
      skipping ||= destination_group?(text, start)
      idx = start + 1
      while idx < text.length
        case text[idx]
        when "{"
          idx = parse_group(text, idx, out, skipping: skipping)
        when "}"
          return idx + 1
        when "\\"
          idx = parse_control(text, idx, out, skipping)
        else
          out << text[idx] unless skipping
          idx += 1
        end
      end
      idx
    end

    def destination_group?(text, brace_index)
      DEST_START_RX.match?(text[brace_index..])
    end

    # Handle a backslash escape or control word.
    # @return [Integer] index just past the control sequence
    def parse_control(text, idx, out, skipping) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      case text[idx + 1]
      when "\\", "{", "}"
        out << text[idx + 1] unless skipping
        idx + 2
      when "'"
        emit_cp1252_byte(text[idx + 2, 2], out) unless skipping
        idx + 4
      when "u"
        match = UNICODE_RX.match(text[idx..])
        return idx + 2 unless match

        out << [match[1].to_i].pack("U") unless skipping
        # the spec's \ucN fallback character follows the codepoint
        idx + match[0].length + 1
      else
        match = WORD_RX.match(text[idx..])
        return idx + 2 unless match

        emit_control_word(match[1].downcase, out) unless skipping
        idx + match[0].length
      end
    end

    def emit_cp1252_byte(hex_digits, out)
      byte = hex_digits.to_i(16)
      return if byte.zero?

      out << byte.chr(Encoding::CP1252).encode(Encoding::UTF_8)
    end

    def emit_control_word(word, out)
      case word
      when "par", "line" then out << "\n"
      when "tab" then out << "\t"
      end
    end
  end
end
