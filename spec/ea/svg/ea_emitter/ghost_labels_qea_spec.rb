# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe "QEA connector ghost labels" do
  let(:document) { Ea::Sources::Qea::Adapter.from_path("examples/qea/20251010_current_plateau_v5.1.qea") }
  include QeaGhostLabelHelpers

  it "omits names of classifiers that only appear on undrawn connectors" do
    expect(qea_italic_names(document, "38170608")).not_to include("FacilityIdAttribute", "FacilityTypeAttribute",
                                                                  "FacilityAttribute", "DmAttribute")
  end

  it "keeps the italic parent name drawn in a class header" do
    expect(qea_italic_names(document, "8DAB169F")).to include("_CityObject")
  end
end
