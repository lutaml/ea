# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "QEA package tab content widths" do
  include QeaPackageTabWidthHelpers

  it "fits the Cambria ApplicationSchema stereotype and preserves minimum-width tabs" do
    document = package_width_document("20251010_current_plateau_v5.1")
    widths = package_tab_widths(document, "2A5E0832-06BE-4381-85D4-9B00E4F95575")

    expect(widths.slice("uro", "core", "luse")).to eq("uro" => 108, "core" => 105, "luse" => 105)
  end

  it "fits the normal applicationSchema stereotype in test.qea" do
    document = package_width_document("test")
    schema = package_tab_widths(document, "F4C23F9E-DD74-4fed-B75D-AD3C6448BA24")

    expect(schema.fetch("Test Schema")).to eq(107)
  end

  it "measures bold package names and preserves the familyless sizing API" do
    renderer = Ea::Svg::EaEmitter::Element::PackageShapeRenderer
    options = { label: "Association Classes", stereotype: nil, size: 7 }

    expect(renderer.autosized_tab_width(**options, family: "Cambria")).to eq(106)
    expect(renderer.autosized_tab_width(**options)).to eq(105)
  end
end

RSpec.describe "ArcGIS package tab content widths" do
  include QeaPackageTabWidthHelpers

  it "fits the bold Association Classes name in the source package family" do
    document = package_width_document("ArcGISWorkspace_template")
    widths = package_tab_widths(document, "7D960BD8-65D8-4934-9C11-4EF860DD8FBA")

    expect(widths.fetch("Association Classes")).to eq(106)
  end
end
