# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Computes the (min_x, min_y, width, height) tuple for a
      # Diagram's canvas. Encapsulates the union rules so Canvas
      # stays a small value-object with just coordinate translation
      # and formatting concerns.
      #
      # Corpus-verified against 3,663 EA-published reference SVGs:
      # EA's canvas covers the ELEMENT RECTS only — connector
      # waypoints, arrow markers, and package-tab overhangs do NOT
      # extend it. Width = element extent + 85 is exact on 72% of
      # the corpus; height = element extent + 76 exact on 50% (the
      # remainder carry invisible per-diagram reservations below
      # the content).
      class BoundsCalculator
        # EA's canvas includes non-uniform frame insets around the
        # element content. Reverse-engineered from reference SVG
        # byte-diff: maintenance diagram has element 169x80 at
        # logical (0,0), ref canvas is 254x177 with element at
        # (35, 40). So:
        #   canvas_width  = element_width + INSET_LEFT + INSET_RIGHT
        #   canvas_height = element_height + INSET_TOP + INSET_BOTTOM
        # The top inset accommodates the frame tab + label space
        # above the element. The bottom inset 36 matches the
        # dominant corpus mode (50% of 3,663 diagrams).
        INSET_LEFT = 35
        INSET_RIGHT = 50
        INSET_TOP = 40
        INSET_BOTTOM = 36

        attr_reader :diagram, :model_index

        def initialize(diagram, model_index: nil)
          @diagram = diagram
          @model_index = model_index
        end

        attr_reader :effective_inset_left

        def compute
          points = element_points
          return [0, 0, 1, 1] if points.empty?

          xs = points.map(&:first)
          ys = points.map(&:last)
          min_x = xs.min || 0
          min_y = ys.min || 0
          # When the leftmost element touches stored x=0 the left
          # inset is 30, not 35 (all five such sample diagrams are
          # exactly 5px narrower; min_x>0 diagrams keep 35). Canvas
          # translation must use the same value.
          @effective_inset_left = min_x.zero? ? INSET_LEFT - 5 : INSET_LEFT
          [
            min_x,
            min_y,
            (xs.max - min_x) + @effective_inset_left + INSET_RIGHT,
            (ys.max - min_y) + INSET_TOP + INSET_BOTTOM
          ]
        end

        private

        # Element x-extent: logical bounds only (matches EA's canvas
        # left/right exactly).
        # Element y-extent: union of logical + image_bounds (image
        # extends below bounds for shadow / image padding), plus the
        # "(from Parent)" subtitle extent: EA draws the subtitle 15px
        # below the body and its text descent adds ~4 more, reserving
        # 19px of canvas below subtitle-bearing packages (the +19
        # height family: 05DF5000 Main, Metadata All, package
        # Clients/Suppliers contexts).
        SUBTITLE_CANVAS_EXTRA = 19

        def subtitle_points
          pts = []
          (diagram.elements || []).each do |e|
            primary = e.bounds || e.image_bounds
            next unless primary
            next unless subtitle_extends_below?(e)

            pts << [primary.x, primary.y + primary.height +
                                 SUBTITLE_CANVAS_EXTRA]
          end
          pts
        end

        def element_points
          pts = []
          (diagram.elements || []).each do |e|
            primary = e.bounds || e.image_bounds
            if primary
              pts << [primary.x, primary.y]
              pts << [primary.x + primary.width, primary.y + primary.height]
              if subtitle_extends_below?(e)
                pts << [primary.x, primary.y + primary.height +
                                     SUBTITLE_CANVAS_EXTRA]
              end
            end
            if e.bounds && e.image_bounds
              ib = e.image_bounds
              pts << [ib.x, ib.y]
              pts << [ib.x + ib.width, ib.y + ib.height]
            end
          end
          pts
        end

        # Mirrors Compartment::PackageFromParent's render conditions:
        # the subtitle draws only on ShowForeign diagrams for a
        # placed package whose parent differs from the diagram's
        # package.
        def subtitle_extends_below?(element)
          return false unless model_index
          return false unless diagram.show_foreign

          pkg = model_index[element.model_element_ref]
          return false unless pkg.is_a?(Ea::Model::Package)

          parent_id = pkg.parent_id
          return false if parent_id.nil? || parent_id.empty?
          return false if parent_id == diagram.package_id

          model_index[parent_id].is_a?(Ea::Model::Package)
        end
      end
    end
  end
end
