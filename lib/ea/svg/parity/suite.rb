# frozen_string_literal: true

require "nokogiri"

module Ea
  module Svg
    module Parity
      # Drives Checker and Differ across every diagram in a Document
      # that has a matching reference SVG. Drives from any source
      # the Document supports (qea or xmi) since the Document is
      # format-agnostic.
      class Suite
        ELEMENT_TYPES = %i[rect polygon path text].freeze
        TEXT_DELTAS = %i[moved_text missing_text extra_text wrong_font wrong_size wrong_weight].freeze
        GEOMETRY_DELTAS = %i[dx dy dwidth dheight max_point_delta].freeze

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
          DiagramReport.new(diagram: diagram, report: checker.report,
                            differ: Differ.new(ours: ours, reference: reference))
        end

        # Epsilon applies to measured geometry; text/font mismatches retain
        # Differ's classification (including its text movement threshold).
        Tolerances = Data.define(:epsilon) do
          def initialize(epsilon: Differ::EPSILON)
            raise ArgumentError, "epsilon must be finite and non-negative" unless epsilon.finite? && epsilon >= 0

            super
          end
        end

        DiagramReport = Struct.new(:diagram, :report, :differ, keyword_init: true) do
          def delta_summary(tolerances = Tolerances.new)
            texts = differ.text_deltas
            TEXT_DELTAS.to_h { |key| [key, texts[key].size] }.merge(
              missing_shapes: differ.shape_summary[:missing],
              extra_shapes: differ.shape_summary[:extra],
              shape_geometry: geometry_count(tolerances),
              **connector_summary(tolerances)
            )
          end

          def clean?(tolerances = Tolerances.new)
            delta_summary(tolerances).values.all?(&:zero?)
          end

          def geometry_count(tolerances)
            differ.shape_deltas.count do |delta|
              delta.slice(*GEOMETRY_DELTAS).values.any? { |value| value.abs > tolerances.epsilon }
            end
          end
          private :geometry_count

          def connector_summary(tolerances)
            deltas = differ.connector_deltas
            {
              source_endpoints: deltas.count { |delta| delta[:source_delta] > tolerances.epsilon },
              target_endpoints: deltas.count { |delta| delta[:target_delta] > tolerances.epsilon },
              arrowhead_tips: deltas.sum do |delta|
                delta[:arrowhead_deltas].count { |head| head[:tip_delta] > tolerances.epsilon }
              end
            }
          end
          private :connector_summary

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

        # Collects diagram results and aggregates counts across the suite.
        class Report
          attr_reader :per_diagram

          def initialize(per_diagram:)
            @per_diagram = per_diagram
          end

          def failures(tolerances = Tolerances.new)
            per_diagram.reject { |diagram| diagram.clean?(tolerances) }
          end

          def total
            per_diagram.size
          end

          def matched(shape_tolerance: 5)
            per_diagram.count { |dr| dr.report.shape_delta_total <= shape_tolerance }
          end

          def aggregate_shape_counts
            %i[ours reference].to_h do |side|
              counts = ELEMENT_TYPES.to_h do |type|
                [type, per_diagram.sum { |dr| dr.report.public_send(type).public_send(side) }]
              end
              [side, counts]
            end
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
