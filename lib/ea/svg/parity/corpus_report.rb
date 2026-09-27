# frozen_string_literal: true

require "json"

module Ea
  module Svg
    module Parity
      # Renders every diagram of a Document and diffs it against the
      # EA-authored reference export for that diagram (EAID_-named
      # files), aggregating itemized deltas into a corpus report.
      #
      # References stay wherever EA published them (e.g. an EA "Save
      # as image" directory); nothing is copied into the gem.
      class CorpusReport
        DELTA_KEYS = %i[extra_text missing_text moved_text wrong_font
                        wrong_size wrong_weight].freeze

        attr_reader :document, :ref_dir

        def initialize(document:, ref_dir:)
          @document = document
          @ref_dir = ref_dir
        end

        # Returns { diagrams: [...], totals: {...} } and writes JSON
        # when output_path is given.
        def run(output_path: nil)
          index = document.index_by_id
          rows = diagrams_with_references.map do |diagram|
            measure_one(diagram, index)
          end.compact

          result = { totals: totals(rows), diagrams: rows }
          File.write(output_path, JSON.pretty_generate(result)) if output_path
          result
        end

        private

        def diagrams_with_references
          document.diagrams.select { |d| reference_path_for(d) }
        end

        # EA publishes images as EAID_<guid-with-underscores>.svg;
        # fall back to the raw diagram id for non-QEA sources.
        def reference_path_for(diagram)
          [
            File.join(ref_dir, "EAID_#{diagram.id.tr('-', '_')}.svg"),
            File.join(ref_dir, "#{Ea::Sources::Qea::IdNormalizer.to_eaid(diagram.id)}.svg"),
            File.join(ref_dir, "#{diagram.id}.svg")
          ].find { |p| File.exist?(p) }
        end

        def measure_one(diagram, index)
          ref_path = reference_path_for(diagram)
          return nil unless ref_path

          ours = Ea::Svg::EaEmitter::Document.new(
            diagram, model_index: index, document: document
          ).render
          differ = Differ.new(ours: ours, reference: File.read(ref_path))
          deltas = differ.text_deltas

          {
            id: diagram.id, name: diagram.name,
            deltas: DELTA_KEYS.to_h { |k| [k, deltas[k].size] },
            shapes: differ.shape_summary.slice(:matched, :missing, :extra)
          }
        end

        def totals(rows)
          sum = DELTA_KEYS.to_h { |k| [k, 0] }
          shapes = { matched: 0, missing: 0, extra: 0 }
          rows.each do |row|
            DELTA_KEYS.each { |k| sum[k] += row[:deltas][k] }
            shapes.each_key { |k| shapes[k] += row[:shapes][k] }
          end
          sum.merge(shapes: shapes, diagrams: rows.size)
        end
      end
    end
  end
end
