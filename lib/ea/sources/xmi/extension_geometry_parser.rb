# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Parses EA's packed geometry string from
      # <xmi:Extension>/<elements>/<element>/@geometry. Returns a
      # typed Placement struct with separate fields for placement
      # and bend routing. Label boxes decoded into a Hash keyed by
      # EA's role names (:llb, :llt, :lrt, :lrb).
      module ExtensionGeometryParser
        LABEL_BOX_KEYS = %i[llb llt lrt lrb lmt lmb irhs ilhs].freeze

        module_function

        def parse(geometry_string)
          return Placement.new if geometry_string.nil? || geometry_string.empty?

          kv = split_pairs(geometry_string)
          Placement.new(
            left: int(kv["Left"]),
            top: int(kv["Top"]),
            right: int(kv["Right"]),
            bottom: int(kv["Bottom"]),
            img_left: int(kv["imgL"]),
            img_top: int(kv["imgT"]),
            img_right: int(kv["imgR"]),
            img_bottom: int(kv["imgB"]),
            sx: int(kv["SX"]),
            sy: int(kv["SY"]),
            ex: int(kv["EX"]),
            ey: int(kv["EY"]),
            edge: int(kv["EDGE"]),
            label_boxes: extract_label_boxes(geometry_string),
            path: kv["Path"]
          )
        end

        def split_pairs(str)
          str.split(";").filter_map do |pair|
            next nil unless pair.include?("=")
            next nil if pair.start_with?("$") # $LLB= etc handled separately

            key, value = pair.split("=", 2)
            [key, value] if key && value
          end.to_h
        end

        def int(value)
          return nil if value.nil? || value.empty?

          Integer(value)
        rescue ArgumentError
          nil
        end

        def extract_label_boxes(geometry_string)
          geometry_string.to_s.scan(/\$?([A-Z]{3})=((?:[A-Za-z]{1,4}=-?\d+:)+)/).each_with_object({}) do |(key, body), acc|
            sym = key.downcase.to_sym
            next unless LABEL_BOX_KEYS.include?(sym)
            next if body.nil? || body.empty?

            acc[sym] = parse_label_body(body)
          end
        end

        def parse_label_body(body)
          pairs = body.to_s.split(":").filter_map do |pair|
            next nil unless pair.include?("=")

            k, v = pair.split("=", 2)
            [k, int(v)] if k && v
          end
          hash = pairs.to_h
          LabelBox.new(
            cx: hash["CX"],
            cy: hash["CY"],
            ox: hash["OX"],
            oy: hash["OY"],
            bold: hash["BLD"] == 1,
            italic: hash["ITA"] == 1,
            underline: hash["UND"] == 1,
            hidden: hash["HDN"] == 1,
            align: hash["ALN"],
            direction: hash["DIR"],
            rotation: hash["ROT"]
          )
        end

        Placement = Struct.new(
          :left, :top, :right, :bottom,
          :img_left, :img_top, :img_right, :img_bottom,
          :sx, :sy, :ex, :ey, :edge,
          :label_boxes, :path,
          keyword_init: true
        )

        LabelBox = Struct.new(
          :cx, :cy, :ox, :oy,
          :bold, :italic, :underline, :hidden,
          :align, :direction, :rotation,
          keyword_init: true
        )
      end
    end
  end
end
