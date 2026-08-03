# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # `ea info NAME FILE` — show details of one element by name.
      class Info < Base
        COLUMNS = %i[field value].freeze

        def call
          element = find_element
          unless element
            warn "Element #{name.inspect} not found"
            exit(1)
          end

          rows = build_info(element)
          formatter.render(rows, columns: COLUMNS)
        end

        private

        def name
          options[:name]
        end

        def model
          @model ||= load_database(file_path)
        end

        def find_element
          (model.collections[:objects] || []).find { |o| o.name == name }
        end

        def build_info(element)
          rows = [
            ["id", element.object_id],
            ["name", element.name],
            ["type", element.object_type],
            ["author", element.author],
            ["version", element.version],
            ["package", package_name_for(element)],
            ["stereotypes", stereotypes_for(element).join(", ")],
            ["notes", (element.note || "")[0, 100]]
          ]

          attrs = attributes_for(element)
          rows.concat(attrs.each_with_index.map do |a, i|
            ["attr[#{i}]", "#{a.name}: #{a.type || 'void'}"]
          end)

          rows
        end

        def attributes_for(element)
          (model.collections[:attributes] || [])
            .select { |a| a.object_id == element.object_id }
        end

        def package_name_for(element)
          pkg = (model.collections[:packages] || []).find { |p| p.package_id == element.package_id }
          pkg&.name || "-"
        end

        def stereotypes_for(element)
          xrefs = model.collections[:xrefs] || []
          stereo_xrefs = xrefs.select do |xr|
            xr.client == element.ea_guid && xr.description&.include?("@STEREO")
          end
          stereo_xrefs.map { |xr| xr.description[/Name=([^;]+)/, 1] }.compact
        end
      end
    end
  end
end
