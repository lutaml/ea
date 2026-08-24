# frozen_string_literal: true

require "xmi"

module Ea
  # Boot-time guard against silently-incompatible xmi versions.
  #
  # The QEA-to-XMI transformer depends on xmi features that are not in
  # any released xmi gem yet (`nested_classifier` on
  # Xmi::Uml::PackagedElement, added by lutaml/xmi#94). The gemspec can
  # only declare `xmi >= 0.6.2` until xmi 0.7.0 ships, so a consumer
  # resolving a released xmi would otherwise get SILENT data loss:
  # nested classes are simply dropped from the output.
  #
  # This guard turns that silent loss into a hard, actionable error at
  # require time. Delete it (and tighten the gemspec to `~> 0.7`) once
  # xmi 0.7.0 is released.
  module XmiGuard
    REQUIRED_FEATURE = :nested_classifier

    module_function

    # @raise [Ea::Error] when the loaded xmi gem lacks nestedClassifier
    #   support
    def verify!(feature_present: supported?)
      return if feature_present

      raise Ea::Error,
            "ea requires an xmi version with nestedClassifier support " \
            "(>= 0.7.0); the loaded xmi gem " \
            "(#{defined?(::Xmi::VERSION) ? ::Xmi::VERSION : "unknown version"}) " \
            "does not define Xmi::Uml::PackagedElement##{REQUIRED_FEATURE}. " \
            "Update the xmi gem (until 0.7.0 is released, use the " \
            "lutaml/xmi feat/nested-classifier-mapping branch)."
    end

    # @return [Boolean] whether the loaded xmi gem exposes the feature
    def supported?
      ::Xmi::Uml::PackagedElement.method_defined?(REQUIRED_FEATURE)
    end
  end
end

Ea::XmiGuard.verify!
