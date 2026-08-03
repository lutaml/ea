# frozen_string_literal: true

module Ea
  # Transformations is the legacy entry point for parse and to_uml.
  # Both methods now delegate directly to Ea::Qea, Ea::Xmi, and
  # Ea::Bridge — the per-format parsers and the UML bridge are
  # reached without an intermediate engine layer.
  module Transformations
    class << self
      # Parse an EA file into its native representation.
      #
      # Pure entry point — does NOT require `lutaml-uml`. Returns:
      #   .qea → Ea::Qea::Database
      #   .xmi → Xmi::Sparx::Root
      #
      # To get a Lutaml::Uml::Document instead, use {to_uml}.
      def parse(file_path, options = {})
        ext = File.extname(file_path).downcase
        case ext
        when ".qea"
          Ea::Qea.load(file_path, options[:config])
        when ".xmi", ".xml"
          Ea::Xmi.load(file_path)
        else
          raise Ea::Error,
                "Unsupported file extension #{ext.inspect}. " \
                "Supported: .qea, .xmi"
        end
      end

      # Transform an EA file (or pre-parsed model) into a
      # `Lutaml::Uml::Document`.
      #
      # Bridge entry point — requires the optional `lutaml-uml` gem.
      def to_uml(path_or_model, options = {})
        model = path_or_model.is_a?(String) ? parse(path_or_model, options) : path_or_model

        case model
        when Ea::Qea::Database
          Ea::Bridge::QeaToUml.transform(model, options)
        when ::Xmi::Sparx::Root
          Ea::Bridge::XmiToUml.transform(model)
        else
          raise Ea::Error,
                "Cannot transform #{model.class} to Lutaml::Uml::Document. " \
                "Expected Ea::Qea::Database or Xmi::Sparx::Root."
        end
      end
    end
  end
end
