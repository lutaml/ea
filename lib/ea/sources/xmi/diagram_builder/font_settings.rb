# frozen_string_literal: true

require "nokogiri"

module Ea
  module Sources
    module Xmi
      class DiagramBuilder
        # The XMI gem exposes placement fonts but drops object styleex.
        # Read saved defaults once, then let each placement override them.
        class FontSettings
          def initialize(xmi_path)
            @xmi_path = xmi_path
          end

          def for(placed)
            style = placed.style
            defaults = object_styles.fetch(placed.subject, {})
            placement = ExtensionStyleParser.split_pairs(style.raw.to_s)
            raw_size = saved_size(placement) || saved_size(defaults)
            {
              family: presence(style.font_family) || defaults["font"],
              size: style.font_size || ExtensionStyleParser.scale_font_size(raw_size),
              logical_height: logical_height(raw_size)
            }
          end

          private

          def presence(value)
            value unless value.nil? || value.empty?
          end

          def saved_size(style)
            value = style["fontsz"]
            value if ExtensionStyleParser.int(value)&.nonzero?
          end

          def logical_height(value)
            tenths = ExtensionStyleParser.int(value)
            tenths * 96 / 720 if tenths
          end

          def object_styles
            @object_styles ||= saved_objects.each_with_object({}) do |element, styles|
              id = element.at_xpath("@*[local-name()='idref']")&.value
              style = element.at_xpath("./*[local-name()='style']/@styleex")&.value
              styles[id] = ExtensionStyleParser.split_pairs(style) if id && style
            end
          end

          def saved_objects
            return [] unless @xmi_path

            doc = Nokogiri::XML(File.read(@xmi_path))
            doc.xpath("//*[local-name()='Extension']/*[local-name()='elements']/*[local-name()='element']")
          end
        end
      end
    end
  end
end
