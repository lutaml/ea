# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Header divider on diagrams that hide feature compartments" do
  include CompactHeaderRuleHelpers

  let(:source) { "20251010_current_plateau_v5.1" }

  it "draws no divider when the diagram hides attributes and operations (HideAtts=1, HideOps=1)" do
    context = compact_source_context(source, "4881CEEE", "_AbstractBuilding")
    expect(context.classifier.properties.reject(&:association_id)).not_to be_empty
    expect(context.content_below_header?).to be(false)
    expect(Ea::Svg::EaEmitter::Compartment::HeaderDivider.render(context)).to be_nil
  end

  it "keeps the divider for the same kind of class on a diagram that shows its features" do
    context = compact_source_context(source, "0114FD24", "AbstractConstruction")
    expect(context.content_below_header?).to be(true)
    expect(Ea::Svg::EaEmitter::Compartment::HeaderDivider.render(context)).to include("<path")
  end
end
