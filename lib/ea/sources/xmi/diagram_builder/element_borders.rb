# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      class DiagramBuilder
        # An element placed without its own LWth takes the border width saved on
        # the model element (<style appearance="...BorderWidth=n;...">), the same
        # t_object.BorderWidth fallback the QEA source applies. Checked on
        # AB281AC1, where the missing width left the Association 1px long.
        class ElementBorders
          def initialize(root)
            @elements = root.extension&.elements&.element.to_a.to_h { |element| [element.idref, element] }
          end

          def width_for(subject)
            appearance = @elements[subject]&.style&.appearance.to_s
            raw = ExtensionStyleParser.split_pairs(appearance)["BorderWidth"]
            return nil if raw.nil? || raw.to_i.negative?

            [raw.to_i, 1].max
          end
        end
      end
    end
  end
end
