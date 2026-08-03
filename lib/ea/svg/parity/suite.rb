# frozen_string_literal: true

require "nokogiri"

module Ea
  module Svg
    module Parity
      # Drives Parity::Checker across every diagram in a Document
      # that has a matching reference SVG. Drives from any source
      # the Document supports (qea or xmi) since the Document is
      # format-agnostic.
      class Suite
        ELEMENT_TYPES = %i[rect polygon path text].freeze

        attr_reader :document, :ref_dir

        def initialize(document, ref_dir)
          @document = document
          @ref_dir = ref_dir
        end

        def measure
          per_diagram = diagrams_with_references.map { |d| measure_one(d) }
          Report.new(per_diagram: per_diagram)
        end

        private

        def diagrams_with_references
          document.diagrams.select { |d| reference_path_for(d) }
        end

        def reference_path_for(diagram)
          # XMI sources already use the EAID_... filename. QEA
          # sources use the GUID form ("F4C23F9E-..."); try both.
          paths = [
            File.join(ref_dir, "#{diagram.id}.svg"),
            File.join(ref_dir, "#{Ea::Sources::Qea::IdNormalizer.to_eaid(diagram.id)}.svg")
          ]
          paths.find { |p| File.exist?(p) }
        end

        def measure_one(diagram)
          ref_path = reference_path_for(diagram)
          ours = Ea::Svg::EaEmitter::Document.new(diagram,
                                                  model_index: document.index_by_id,
                                                  document: document).render
          reference = File.read(ref_path)
          checker = Checker.new(ours: ours, reference: reference)
          DiagramReport.new(diagram: diagram, report: checker.report)
        end

        DiagramReport = Struct.new(:diagram, :report, keyword_init: true) do
          def id
            diagram.id
          end

          def name
            diagram.name
          end

          def type
            diagram.diagram_type
          end
        end

        class Report
          attr_reader :per_diagram

          def initialize(per_diagram:)
            @per_diagram = per_diagram
          end

          def total
            per_diagram.size
          end

          def matched(shape_tolerance: 5)
            per_diagram.count { |dr| dr.report.shape_delta_total <= shape_tolerance }
          end

          def aggregate_shape_counts
            ours = { rect: 0, polygon: 0, path: 0, text: 0 }
            ref = { rect: 0, polygon: 0, path: 0, text: 0 }
            per_diagram.each do |dr|
              ours[:rect] += dr.report.rect.ours
              ours[:polygon] += dr.report.polygon.ours
              ours[:path] += dr.report.path.ours
              ours[:text] += dr.report.text.ours
              ref[:rect] += dr.report.rect.reference
              ref[:polygon] += dr.report.polygon.reference
              ref[:path] += dr.report.path.reference
              ref[:text] += dr.report.text.reference
            end
            { ours: ours, reference: ref }
          end

          def text_overlap_avg
            return 0.0 if per_diagram.empty?

            overlaps = per_diagram.map(&:report).map(&:text_overlap)
            overlaps.sum / overlaps.size.to_f
          end

          def outliers(shape_tolerance: 5)
            per_diagram.select { |dr| dr.report.shape_delta_total > shape_tolerance }
          end
        end
      end
    end
  end
end
