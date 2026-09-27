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
            font_size: font_size_match,
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
          font_style_histogram(our_doc, "font-family") ==
            font_style_histogram(ref_doc, "font-family")
        end

        # Exact histogram of every emitted font-size (e.g.
        # {"9.00"=>42, "13.00"=>21}) — a first-text comparison would
        # pass diagrams whose body text renders at the wrong size.
        def font_size_match
          font_style_histogram(our_doc, "font-size") ==
            font_style_histogram(ref_doc, "font-size")
        end

        def font_style_histogram(doc, property)
          doc.css("text").each_with_object(Hash.new(0)) do |node, acc|
            value = (node["style"] || "")[/#{Regexp.quote(property)}:([^;]+)/, 1]
            acc[value] += 1 if value
          end
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

        Diff = Struct.new(:ours, :reference, keyword_init: true) do
          def delta
            ours - reference
          end

          def within?(tolerance)
            delta.abs <= tolerance
          end
        end

        Report = Struct.new(:rect, :path, :polygon, :text, :group,
                            :font_family, :font_size, :view_box, :text_overlap,
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
