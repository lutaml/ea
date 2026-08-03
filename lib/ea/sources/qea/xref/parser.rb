# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      module Xref
        # Pure parser for EA's `t_xref.Description` mini-language.
        # Stateless — every call returns a fresh `Xref::Record`.
        #
        # Supported formats:
        #   @STEREO;Name=X;FQName=Y;@ENDSTEREO;
        #   @PROP=@NAME=..@ENDNAME;@TYPE=..@ENDTYPE;@VALU=..@ENDVALU;@PRMT=..@ENDPRMT;@ENDPROP;
        #   <key>=<value>;<key>=<value>;
        #
        # Unknown formats fall through to key=value parsing.
        module Parser
          module_function

          # Parse one Description string into a typed Record.
          # @param description [String, nil]
          # @return [Ea::Sources::Qea::Xref::Record]
          def parse(description)
            return Record.new if description.nil? || description.empty?

            Record.new(
              stereotype: parse_stereotype(description),
              properties: parse_properties(description),
              legends: parse_legends(description),
              key_values: parse_key_values(description),
              raw: description
            )
          end

          # -- per-format extractors ----------------------------------

          # Matches both legacy `@STEREO;Name=X;GUID={..};` and the
          # plateau form `@STEREO;Name=X;FQName=Y;@ENDSTEREO;`.
          STEREO_REGEX = /
            @STEREO;
            (.*?)
            (?:@ENDSTEREO;|\z)
          /mx.freeze

          def parse_stereotype(description)
            match = description.match(STEREO_REGEX)
            return nil unless match

            fields = parse_semicolon_fields(match[1])
            StereotypeApplication.new(
              name: fields["Name"],
              fqname: fields["FQName"]
            )
          end

          # One Description can carry multiple @PROP=...@ENDPROP; blocks.
          # Split, then classify each as PropertyDefinition or LegendDefinition.
          PROP_REGEX = /
            @PROP=
            (.*?)
            @ENDPROP;
          /mx.freeze

          def parse_properties(description)
            blocks = description.scan(PROP_REGEX).flatten
            blocks.each_with_object([]) do |block, acc|
              record = build_prop_record(block)
              acc << record if record
            end
          end

          def parse_legends(description)
            parse_properties(description).select do |prop|
              prop.is_a?(LegendDefinition)
            end
          end

          def build_prop_record(block)
            name = extract_tagged_value(block, "NAME")
            type = extract_tagged_value(block, "TYPE")
            value = extract_tagged_value(block, "VALU")
            parameter = extract_tagged_value(block, "PRMT")

            if type&.start_with?("LEGEND_")
              LegendDefinition.new(
                name: name,
                legend_type: type,
                colors: parse_color_value(value),
                parameter: parameter
              )
            else
              PropertyDefinition.new(
                name: name,
                type: type,
                value: value,
                parameter: parameter
              )
            end
          end

          # Extracts the content between @TAG=...@ENDTAG; markers.
          # Returns nil when the tag is absent.
          def extract_tagged_value(block, tag)
            pattern = /@#{tag}=(.*?)@END#{tag};/m.freeze
            match = block.match(pattern)
            match ? match[1] : nil
          end

          # EA encodes legend VALU as `#key#=value;` pairs.
          # Returns a hash keyed by underscored symbol.
          def parse_color_value(value)
            return {} if value.nil? || value.empty?

            value.scan(/#([^#=]+)#=([^;]*);/).each_with_object({}) do |(k, v), acc|
              acc[k.downcase.to_sym] = v
            end
          end

          # Legacy `Key=Value;Key=Value;` parsing. Skips content that
          # looks like @STEREO or @PROP blocks to avoid noise.
          def parse_key_values(description)
            stripped = description
                       .gsub(/@STEREO;.*?(?:@ENDSTEREO;|\z)/m, "")
                       .gsub(/@PROP=.*?@ENDPROP;/m, "")
            pairs = stripped.split(";").map { |s| s.split("=", 2) }
            pairs.each_with_object({}) do |(k, v), acc|
              next if k.nil? || k.empty? || v.nil?

              acc[k.downcase.to_sym] = v
            end
          end

          # Parse `Key=Value;Key=value;` into a string-keyed hash.
          # Used internally for the @STEREO body fields.
          def parse_semicolon_fields(body)
            body.split(";").each_with_object({}) do |part, acc|
              key, value = part.split("=", 2)
              next if key.nil? || key.empty? || value.nil?

              # Strip @END* terminators that may be attached when the
              # body wasn't cleanly split (defensive — usually already
              # consumed by STEREO_REGEX).
              cleaned = value.sub(/@END\w+\z/, "")
              acc[key] = cleaned
            end
          end
        end
      end
    end
  end
end
