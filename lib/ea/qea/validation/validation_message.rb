# frozen_string_literal: true

require "lutaml/model"

module Ea
  module Qea
    module Validation
      # Represents a single validation message with severity, category, and
      # context information. Serialization (hash/JSON, with nil optional
      # fields omitted) is declared through lutaml-model mappings.
      #
      # @example Creating an error message
      #   message = ValidationMessage.new(
      #     severity: :error,
      #     category: :missing_reference,
      #     entity_type: :association,
      #     entity_id: "FA86EB3B-198A-4141-83F6-DE9FACC76425",
      #     entity_name: "Association_1",
      #     field: "member_end",
      #     reference: "GPLR_Compression",
      #     message: "member_end references non-existent class",
      #     location: "Package::SubPackage"
      #   )
      class ValidationMessage < Lutaml::Model::Serializable
        # Severity levels for validation messages (string tags; symbol
        # inputs are normalized by the attribute cast)
        module Severity
          ERROR = "error"     # Breaks integrity, must fix
          WARNING = "warning" # May cause issues, should review
          INFO = "info"       # Informational, may be intentional
        end

        # Categories of validation issues
        module Category
          MISSING_REFERENCE = "missing_reference"
          ORPHANED = "orphaned"
          DUPLICATE = "duplicate"
          INVALID_TYPE = "invalid_type"
          CIRCULAR_REFERENCE = "circular_reference"
          MISSING_REQUIRED = "missing_required"
          CONSTRAINT_VIOLATION = "constraint_violation"
        end

        attribute :severity, :string
        attribute :category, :string
        attribute :entity_type, :string
        attribute :entity_id, :string
        attribute :entity_name, :string
        attribute :field, :string
        attribute :reference, :string
        attribute :message, :string
        attribute :location, :string
        attribute :context, :hash, default: -> { {} }

        json do
          map "severity", to: :severity, render_nil: :omit
          map "category", to: :category, render_nil: :omit
          map "entity_type", to: :entity_type, render_nil: :omit
          map "entity_id", to: :entity_id, render_nil: :omit
          map "entity_name", to: :entity_name, render_nil: :omit
          map "field", to: :field, render_nil: :omit
          map "reference", to: :reference, render_nil: :omit
          map "message", to: :message, render_nil: :omit
          map "location", to: :location, render_nil: :omit
          map "context", to: :context, render_nil: :omit
        end

        yaml do
          map "severity", to: :severity, render_nil: :omit
          map "category", to: :category, render_nil: :omit
          map "entity_type", to: :entity_type, render_nil: :omit
          map "entity_id", to: :entity_id, render_nil: :omit
          map "entity_name", to: :entity_name, render_nil: :omit
          map "field", to: :field, render_nil: :omit
          map "reference", to: :reference, render_nil: :omit
          map "message", to: :message, render_nil: :omit
          map "location", to: :location, render_nil: :omit
          map "context", to: :context, render_nil: :omit
        end

        # Checks if this is an error message
        #
        # @return [Boolean]
        def error?
          severity == Severity::ERROR
        end

        # Checks if this is a warning message
        #
        # @return [Boolean]
        def warning?
          severity == Severity::WARNING
        end

        # Checks if this is an info message
        #
        # @return [Boolean]
        def info?
          severity == Severity::INFO
        end

        # Returns a formatted string representation of the message
        #
        # @return [String]
        def to_s # rubocop:disable Metrics/AbcSize
          parts = []
          parts << "#{entity_type.to_s.capitalize} '#{entity_name}'"
          parts << "{#{entity_id}}"
          parts << "└─ #{message}"
          parts << "└─ Field: #{field}" if field
          parts << "└─ Reference: #{reference}" if reference
          parts << "└─ Location: #{location}" if location
          parts.join("\n")
        end

        # Symbol-keyed view of the message. The canonical serialization
        # (nil fields omitted) is the string-keyed framework output via
        # #to_hash / #to_json.
        #
        # @return [Hash]
        def to_h
          to_hash.transform_keys(&:to_sym)
        end
      end
    end
  end
end
