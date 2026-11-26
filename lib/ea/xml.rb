# frozen_string_literal: true

module Ea
  # Shared XML parse entry for the gem's direct parses. Lenient by
  # default — nokogiri/libxml2 parity — tolerating files whose bytes
  # do not match UTF-8 (EA exports declare windows-1252 regularly and
  # bundle raw CP1252 bytes alongside).
  module Xml
    DECLARED_ENCODING = /\A\s*<\?xml[^>]*encoding=["']([^"']+)["']/

    module_function

    # @param path [String] file path
    # @return [Moxml::Wrappers::Document]
    def parse_file(path)
      parse(File.read(path))
    end

    # @param content [String] XML text
    # @return [Moxml::Wrappers::Document]
    def parse(content)
      context = Moxml.new
      context.config.strict_parsing = false
      context.parse(normalize_encoding(content))
    end

    # libxml2 transcoded according to the XML declaration; moxml's
    # parse validates UTF-8 strictly regardless of the declaration.
    # Transcode declared non-UTF-8 content to UTF-8 and rewrite the
    # declaration so downstream sees consistent text.
    def normalize_encoding(content)
      declared = content[DECLARED_ENCODING, 1]
      return content if declared.nil? || declared.casecmp?("utf-8")

      text = content.dup.force_encoding(declared).encode("UTF-8")
      text.sub!(/\A(\s*<\?xml[^>]*encoding=["'])([^"']+)/) do
        "#{Regexp.last_match(1)}UTF-8"
      end
      text
    rescue StandardError
      content.valid_encoding? ? content : content.scrub
    end
  end
end
