# frozen_string_literal: true

require "xmi"

module Ea
  module Xmi
    # The result of loading an export into the EA graph: the parser,
    # the parsed document, and the indexes the consumers resolve
    # through.
    Loaded = Struct.new(:parser, :uml_document, :drop_options,
                        :xmi_id_index, keyword_init: true)

    module Loader
      # Whole load parses the entire export. Partial load parses only
      # the reference closure of the wanted [package, name] pairs,
      # assembled in memory by Ea::Xmi::Slicer - no temporary files.
      # Both modes produce identical content for everything derived
      # from the model's elements; partial load exists so a consumer
      # reading a handful of classes out of a large export never has
      # to hydrate the whole of it. package may be nil, matching by
      # name in any package.
      def self.call(source, partial: nil)
        xml = read(source)
        xml = Slicer.slice(xml, partial) if partial
        ::Xmi::Sparx::Root.parse_xml(xml)
      end

      def self.graph(source, partial: nil)
        parser = Parser.new
        uml_document = parser.parse(call(source, partial: partial))
        Loaded.new(
          parser: parser,
          uml_document: uml_document,
          drop_options: build_drop_options(parser),
          xmi_id_index: build_xmi_id_index(uml_document),
        )
      end

      def self.read(source)
        source.respond_to?(:read) ? source.read : File.read(source.to_s)
      end

      def self.build_drop_options(parser)
        lookup = LookupService.new(parser)
        {
          xmi_root_model: parser.xmi_root_model,
          id_name_mapping: parser.id_name_mapping,
          lookup: lookup,
          with_gen: true,
          with_assoc: true,
          with_absolute_path: true,
        }
      end

      # One xmi_id -> node walk per parse.
      def self.build_xmi_id_index(uml_document)
        index = {}
        collect = lambda do |container|
          index[container.xmi_id] ||= container if container.respond_to?(:xmi_id)
          if container.respond_to?(:classes)
            container.classes.each { |n| index[n.xmi_id] ||= n }
          end
          if container.respond_to?(:data_types)
            container.data_types.each { |n| index[n.xmi_id] ||= n }
          end
          if container.respond_to?(:enums)
            container.enums.each { |n| index[n.xmi_id] ||= n }
          end
          (container.packages || []).each { |p| collect.call(p) } if container.respond_to?(:packages)
        end
        collect.call(uml_document)
        index
      end
    end
  end
end
