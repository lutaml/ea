# frozen_string_literal: true

module Ea
  module Mdg
    # Stereotype alias resolver. Loads EA's GMLStereotypes.xml (or
    # equivalent) and maps variant spellings to a canonical name.
    #
    # Source XML format:
    #   <Stereotypes>
    #     <Stereotype name="FeatureType">
    #       <Alias>Feature Type</Alias>
    #       <Alias>featureType</Alias>
    #       <Alias>featuretype</Alias>
    #     </Stereotype>
    #   </Stereotypes>
    #
    # Usage:
    #   registry = StereotypeAliasRegistry.from_path("GMLStereotypes.xml")
    #   registry.canonicalize("featuretype")  # → "FeatureType"
    #   registry.canonicalize("unknown")      # → "unknown" (passthrough)
    class StereotypeAliasRegistry
      attr_reader :aliases

      # @param aliases [Hash{String => String}] alias → canonical name
      def initialize(aliases = {})
        @aliases = aliases
      end

      # Build a registry by parsing the GMLStereotypes.xml format.
      # @param path [String] path to XML file
      # @return [StereotypeAliasRegistry]
      def self.from_path(path)
        return new if path.nil? || !File.exist?(path)

        require "nokogiri"
        doc = Nokogiri::XML(File.read(path))
        from_nokogiri(doc)
      end

      # Build from a parsed Nokogiri document. Tested separately so
      # the parser path is exercised without file IO.
      # @param doc [Nokogiri::XML::Document]
      # @return [StereotypeAliasRegistry]
      def self.from_nokogiri(doc)
        aliases = {}
        doc.xpath("//Stereotype").each do |stereo|
          canonical = stereo["name"]
          next unless canonical

          aliases[canonical.downcase] = canonical
          stereo.xpath("Alias").each do |alias_node|
            text = alias_node.text.strip
            next if text.empty?

            aliases[text.downcase] = canonical
          end
        end
        new(aliases)
      end

      # Map a variant spelling to the canonical form. Case-insensitive.
      # Unknown stereotypes pass through unchanged.
      # @param name [String, nil]
      # @return [String, nil]
      def canonicalize(name)
        return nil if name.nil? || name.empty?

        aliases[name.downcase] || name
      end

      # @return [Array<String>] all canonical stereotype names
      def canonical_names
        aliases.values.uniq
      end
    end
  end
end
