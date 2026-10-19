# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Legacy entry point preserved for backward compatibility.
        # Delegates to HeaderLinePipeline — the OCP-friendly provider
        # chain that replaces this module. New code should call
        # HeaderLinePipeline directly.
        module HeaderLines
          module_function

          def for(classifier, **opts)
            HeaderLinePipeline.for(classifier, **opts)
          end

          # A parent followed directly by the name has a 3px gap beyond
          # the row pitch. A class stereotype needs 6px; interfaces use 3px.
          def parent_ghost_gap(lines)
            style = lines.dig(0, 1)
            return 0 unless %i[italic italic_tight].include?(style)

            style == :italic_tight || %i[bold bold_italic].include?(lines.dig(1, 1)) ? 3 : 6
          end

          # Delegate to the Name provider so historical callers and
          # specs that test display_name keep working.
          def display_name(classifier, *_)
            HeaderLineProvider::Name.display_name(classifier)
          end
        end
      end
    end
  end
end
