# frozen_string_literal: true

module Ea
  module Lint
    # Base class for lint rules. Subclasses implement #check(model)
    # and return an Array<Offense>. Default severity is :warning;
    # subclasses can override via `self.severity`.
    class LintRule
      class << self
        attr_accessor :severity
      end

      def self.name
        to_s.split("::").last.gsub(/Rule\z/, "").gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      end

      def self.severity
        @severity || :warning
      end

      def check(_model)
        raise NotImplementedError, "#{self.class}#check not implemented"
      end

      protected

      def offense(entity_id:, entity_name:, message:, severity: nil)
        Offense.new(
          rule: self.class.name,
          severity: severity || self.class.severity,
          entity_id: entity_id,
          entity_name: entity_name,
          message: message
        )
      end
    end
  end
end
