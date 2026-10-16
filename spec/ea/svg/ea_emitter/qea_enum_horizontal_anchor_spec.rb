# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA enumeration horizontal anchors" do
  include QeaContentHelpers

  let(:document) { Ea::Sources::Qea::Adapter.from_path("examples/qea/20251010_current_plateau_v5.1.qea") }
  let(:nodes) { qea_text_nodes(document, "516DA1A2") }
  let(:enumeration) { document.classifiers.find { |entry| entry.name == "LandSlideTypeValue" } }

  it "aligns all published Cambria literal names with the compact attribute inset" do
    rows = nodes.select { |node| enumeration.literals.map(&:name).include?(node.text) }

    # EA reference x=473, plus the diagram's accepted 25-unit translation.
    expect(rows.size).to eq(18)
    expect(rows.map { |node| node["style"] }).to all(include("font-family:Cambria;", "font-size:7pt;"))
    expect(rows.map { |node| node["x"].to_f }).to eq([498] * 18)
    expect(rows.map { |node| node["y"].to_f }).to eq((223..427).step(12).to_a)
  end

  it "preserves the enumeration header and caption anchors" do
    positions = ["urg::LandSlideTypeValue", "literals"].map do |content|
      node = nodes.find { |entry| entry.text == content }
      [node["x"].to_f, node["y"].to_f]
    end

    expect(positions).to eq([[562, 190], [604, 211]])
  end
end
