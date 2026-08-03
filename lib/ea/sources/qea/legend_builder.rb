# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Builds an `Ea::Model::Legend` for a Text element by parsing
      # the sibling `t_xref` row of name="CustomProperties" on the
      # same GUID. EA encodes legend configuration in the xref's
      # Description field using `@PROP=...@ENDPROP;` blocks, one
      # per item plus one for the title (`LEGEND_STYLE_SETTINGS`).
      #
      # Returns nil when no matching xref exists (the Text element
      # is not a legend — caller should render it as a plain note).
      class LegendBuilder
        LEGEND_XREF_NAME = "CustomProperties"
        LEGEND_TYPE_OBJECT_STYLE = "LEGEND_OBJECTSTYLE"
        LEGEND_TYPE_STYLE_SETTINGS = "LEGEND_STYLE_SETTINGS"

        PROP_PATTERN = /
          @PROP=
          @NAME=(?<name>[^@]*?)@ENDNAME;
          @TYPE=(?<type>[^@]*?)@ENDTYPE;
          @VALU=(?<value>[^@]*?)@ENDVALU;
          (?:@PRMT=(?<prmt>[^@]*?)@ENDPRMT;)?
          @ENDPROP;
        /x.freeze

        attr_reader :database

        def initialize(database)
          @database = database
        end

        def build_for(ea_guid)
          description = legend_description_for(ea_guid)
          return nil unless description

          build_from_description(description)
        end

        private

        def legend_description_for(ea_guid)
          xref = database.xrefs_for_client(ea_guid).find { |row| row.name == LEGEND_XREF_NAME }
          return nil unless xref

          xref.description
        end

        def build_from_description(description)
          props = description.scan(PROP_PATTERN)
          return nil if props.empty?

          items = items_from(props)
          style = style_settings_from(props)

          build_legend(items: items, style: style)
        end

        def items_from(props)
          props.select { |_, type, _, _| type == LEGEND_TYPE_OBJECT_STYLE }
               .each_with_index
               .map do |(name, _, value, prmt), display_index|
                 build_item(name: name, value: value, prmt: prmt,
                            display_index: display_index)
               end
        end

        def style_settings_from(props)
          entry = props.find { |_, type, _, _| type == LEGEND_TYPE_STYLE_SETTINGS }
          return {} unless entry

          parse_kv(entry[2])
        end

        def build_legend(items:, style:)
          Ea::Model::Legend.new(
            title: style["TITLE"] || Ea::Model::Legend::DEFAULT_TITLE,
            heading_size: int_or_nil(style["HEADINGSIZE"]),
            font_color: int_or(style["FONTCOLOR"],
                               Ea::Model::Legend::DEFAULT_FONT_COLOR),
            background_color: int_or(style["BACKGROUNDCOLOR"],
                                     Ea::Model::Legend::DEFAULT_BACKGROUND_COLOR),
            border_color: int_or(style["BORDERCOLOR"],
                                 Ea::Model::Legend::DEFAULT_BORDER_COLOR),
            background_is_default: background_is_default?(style),
            items: items
          )
        end

        def build_item(name:, value:, prmt:, display_index:)
          attrs = parse_kv(value)
          Ea::Model::LegendItem.new(
            name: name.to_s,
            background_color: int_or(attrs["Back_Ground_Color"], 0),
            pen_color: int_or(attrs["Pen_Color"], 0),
            pen_size: int_or(attrs["Pen_Size"], 1),
            sort_index: int_or(prmt, display_index)
          )
        end

        # EA packs key=value pairs as `#KEY#=VAL;` inside the @VALU
        # payload. Both KEY and VAL are delimited by `#` or `;`.
        def parse_kv(payload)
          return {} if payload.nil? || payload.empty?

          payload.to_s.split(";").each_with_object({}) do |pair, hash|
            key, val = pair.split("=", 2)
            next unless key && val
            next if val.empty?

            hash[key.delete("#")] = val
          end
        end

        def background_is_default?(style)
          value = style["BACKGROUNDISDEFAULT"]
          return true if value.nil?

          value == "1" || value.to_s.downcase == "true"
        end

        def int_or(raw, fallback)
          Integer(raw.to_s)
        rescue ArgumentError, TypeError
          fallback
        end

        def int_or_nil(raw)
          Integer(raw.to_s)
        rescue ArgumentError, TypeError
          nil
        end
      end
    end
  end
end
