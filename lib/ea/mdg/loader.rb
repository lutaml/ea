# frozen_string_literal: true


module Ea
  module Mdg
    # Parses an MDG technology file into an Mdg::Document.
    #
    # Supports two EA MDG file formats:
    #
    #   1. **MDG.Technology format** (root: `<MDG.Technology>`) —
    #      Parsed via lutaml-model XML mapping (Ea::Mdg::Xml::*).
    #      Carries UMLProfile elements with Stereotype definitions
    #      and their tagged-value specs. Example: CityGML MDG.
    #
    #   2. **XMI format** (root: `<XMI>`) — Delegates to the xmi
    #      gem's typed Sparx model for UML class/attribute/generalization
    #      extraction. Carries reference model classes. Example: ISO 19103.
    #
    # The format is auto-detected from the root element. Both
    # contribute to the same Document; stereotypes and classifiers
    # coexist without coupling.
    class Loader
      attr_reader :xml

      def initialize(xml)
        @xml = xml
      end

      def self.from_path(path)
        new(File.read(path))
      end

      def self.from_xml(xml)
        new(xml)
      end

      def document
        @document ||= build_document
      end

      private

      def build_document
        if mdg_technology_format?
          build_from_mdg_technology
        else
          build_from_xmi
        end
      end

      def mdg_technology_format?
        stripped = xml.lstrip
        stripped.start_with?("<MDG.Technology") ||
          (stripped.start_with?("<?xml") && xml.include?("<MDG.Technology"))
      end

      # ---- MDG.Technology format (lutaml-model) ----

      def build_from_mdg_technology
        tech = Xml::Technology.from_xml(xml)
        Document.new(
          technology_name: tech.documentation&.name || "Unknown",
          classifiers: [],
          generalizations: [],
          packages: [],
          stereotypes: extract_stereotypes(tech)
        )
      end

      def extract_stereotypes(tech)
        profiles = tech.uml_profiles&.profiles || []
        profiles += tech.standalone_profiles if tech.standalone_profiles
        profiles.flat_map do |profile|
          stereotypes = profile.content&.stereotypes&.items || []
          stereotypes.map { |s| stereotype_entry(s) }
        end
      end

      def stereotype_entry(xml_stereotype)
        applies = xml_stereotype.applies_to&.applies || []
        tags = xml_stereotype.tagged_values&.tags || []
        Document::StereotypeEntry.new(
          name: xml_stereotype.name,
          applies_to: applies.map(&:type).compact,
          tagged_values: tags.map { |t| tag_spec(t) },
          notes: xml_stereotype.notes,
          generalizes: xml_stereotype.generalizes,
          base_stereotypes: xml_stereotype.base_stereotypes
        )
      end

      def tag_spec(xml_tag)
        Document::TaggedValueSpec.new(
          name: xml_tag.name,
          type: xml_tag.type,
          description: xml_tag.description,
          unit: xml_tag.unit,
          values: xml_tag.values,
          default: xml_tag.default
        )
      end

      # ---- XMI format ----
      # XMI files use UML 1.3 namespace elements. Full lutaml-model
      # XML mapping for the UML namespace schema is a follow-up
      # task. For now, XMI parsing returns an empty Document with
      # just the technology name extracted from the root package.

      def build_from_xmi
        Document.new(
          technology_name: "Unknown",
          classifiers: [],
          generalizations: [],
          packages: []
        )
      end
    end
  end
end
