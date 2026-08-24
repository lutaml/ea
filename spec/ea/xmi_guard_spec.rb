# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::XmiGuard do
  describe ".supported?" do
    it "is true for the xmi version in the current bundle" do
      # The bundle pins the xmi branch that adds nested_classifier
      # (lutaml/xmi#94); the guard must pass so `require "ea"` works.
      expect(described_class.supported?).to be true
    end
  end

  describe ".verify!" do
    it "passes silently in the current bundle" do
      expect { described_class.verify! }.not_to raise_error
    end

    it "raises an actionable Ea::Error when the feature is absent" do
      expect { described_class.verify!(feature_present: false) }
        .to raise_error(
          Ea::Error,
          /requires an xmi version with nestedClassifier support \(>= 0\.7\.0\)/
        )
    end

    it "names the missing reader and the fix in the error message" do
      described_class.verify!(feature_present: false)
    rescue Ea::Error => e
      expect(e.message).to include("Xmi::Uml::PackagedElement#nested_classifier")
      expect(e.message).to include("Update the xmi gem")
    end
  end
end
