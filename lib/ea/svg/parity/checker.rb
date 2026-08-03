# frozen_string_literal: true

require "nokogiri"

module Ea
  module Svg
    module Parity
      # Compares an emitted SVG against one EA reference SVG across
      # element counts, font-family, viewBox, and text overlap.
      class Checker
        ELEMENT_TYPES = %i[rect path polygon text group].freeze

        attr_reader :ours, :reference

        def initialize(ours:, reference:)
          @ours = ours
          @reference = reference
        end

        def report
          Report.new(
            rect: count_diff("rect"),
            path: count_diff("path"),
            polygon: count_diff("polygon"),
            text: count_diff("text"),
            group: top_level_group_diff,
            font_family: font_family_match,
            view_box: view_box_match,
            text_overlap: text_overlap_ratio
          )
        end

        private

        def our_doc
          @our_doc ||= Nokogiri::XML(@ours)
        end

        def ref_doc
          @ref_doc ||= Nokogiri::XML(@reference)
        end

        def count_diff(selector)
          Diff.new(ours: our_doc.css(selector).size,
                   reference: ref_doc.css(selector).size)
        end

        def top_level_group_diff
          Diff.new(ours: our_doc.css("svg > g").size,
                   reference: ref_doc.css("svg > g").size)
        end

        def font_family_match
          our_family = first_text_style(our_doc)[/font-family:([^;]+)/, 1]
          ref_family = first_text_style(ref_doc)[/font-family:([^;]+)/, 1]
          our_family == ref_family
        end

        def view_box_match
          our_doc.root["viewBox"] == ref_doc.root["viewBox"]
        end

        def text_overlap_ratio
          our_set = our_doc.css("text").map(&:text).map(&:strip).to_set
          ref_set = ref_doc.css("text").map(&:text).map(&:strip).to_set
          return 1.0 if our_set.empty? && ref_set.empty?
          return 0.0 if our_set.empty? || ref_set.empty?

          (our_set & ref_set).size.to_f / (our_set | ref_set).size.to_f
        end

        def first_text_style(doc)
          first = doc.css("text").first
          first ? (first["style"] || "") : ""
        end

        Diff = Struct.new(:ours, :reference, keyword_init: true) do
          def delta
            ours - reference
          end

          def within?(tolerance)
            delta.abs <= tolerance
          end
        end

        Report = Struct.new(:rect, :path, :polygon, :text, :group,
                            :font_family, :view_box, :text_overlap,
                            keyword_init: true) do
          def shape_delta_total
            [rect, path, polygon].sum(&:delta).abs
          end

          def text_delta
            text.delta
          end

          def shape_within?(tolerance)
            [rect, path, polygon].all? { |d| d.within?(tolerance) }
          end
        end
      end
    end
  end
end
