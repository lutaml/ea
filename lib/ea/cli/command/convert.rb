# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # `ea convert FILE --to xmi [--output PATH]`
      #
      # Converts an EA file to another format. Currently supports:
      #   --to xmi   .qea → Sparx XMI (direct, full Sparx fidelity)
      #
      # Routing is by input file extension:
      #   .qea → Ea::Transformers.qea_to_xmi (direct path, no intermediate
      #          UML model — preserves all Sparx-specific concepts)
      #   any other extension → UnsupportedFormat
      #
      # Future formats (e.g. parsing a Lutaml::LML .lur file) are added by
      # extending the case statement in {#convert_to_xmi}.
      class Convert < Base
        SUPPORTED_TARGETS = %w[xmi].freeze
        SUPPORTED_INPUT_FORMATS = %i[qea].freeze

        def call
          target = options[:to] or raise Ea::Cli::Error, "missing required --to"
          case target.to_s
          when "xmi" then convert_to_xmi
          else
            raise Ea::Cli::Error,
                  "Unsupported target '#{target}'. " \
                  "Valid: #{SUPPORTED_TARGETS.join(', ')}"
          end
        end

        private

        def convert_to_xmi
          xml = case input_format
                when :qea then qea_to_xmi_xml
                else
                  raise Ea::Cli::UnsupportedFormat.new(
                    file_path,
                    "supported inputs: " \
                    "#{SUPPORTED_INPUT_FORMATS.join(', ')}",
                  )
                end
          path = write_output(xml, default_name: "#{file_path}.xmi")
          formatter.render([[path]], columns: [:written_to])
        end

        def qea_to_xmi_xml
          database = load_database(file_path)
          Ea::Transformers.qea_to_xmi(database)
        ensure
          database&.close_connection
        end

        def input_format
          File.extname(file_path).downcase[1..].to_sym
        end
      end
    end
  end
end
