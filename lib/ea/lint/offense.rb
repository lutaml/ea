# frozen_string_literal: true

module Ea
  module Lint
    # One lint offense. Carries rule name, severity, entity id/name,
    # and a human-readable message.
    Offense = Struct.new(:rule, :severity, :entity_id, :entity_name,
                         :message, keyword_init: true) do
      def error?
        severity == :error
      end

      def warning?
        severity == :warning
      end
    end
  end
end
