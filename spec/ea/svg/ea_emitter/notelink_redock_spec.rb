# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::ConnectorRedock do
  include NotelinkRedockHelpers

  it "clips a thin NoteLink on the resolved target border from QEA styles" do
    # Plateau 9DA6C553: borderless Note -> Population (border 2), EDGE=2.
    document = qea_notelink_document
    diagram = document.diagrams.first
    connector = diagram.connectors.first
    fixture = notelink_fixture
    bounds = diagram.elements.zip(fixture[:drawn_bounds].values).to_h do |element, box|
      [element.model_element_ref, box]
    end

    expect(connector.style[:lwidth]).to eq("0")
    expect(diagram.elements.map(&:line_width)).to eq([0, 2])
    expect(described_class.pairs_for(connector, diagram, document.index_by_id, bounds))
      .to eq([[310, 714], [449, 684]])
  end

  %w[0 1 2].each do |width|
    it "uses element borders independently of NoteLink width #{width}" do
      expect(notelink_pairs(notelink_fixture(width: width))).to eq([[310, 714], [449, 684]])
    end
  end

  [0, 1].each do |border|
    it "keeps the geometric edge for target border #{border}" do
      expect(notelink_pairs(notelink_fixture(border: border))).to eq([[310, 714], [450, 684]])
    end
  end

  it "retains stored waypoints when bounds are unavailable" do
    fixture = notelink_fixture
    fixture[:drawn_bounds] = nil
    expect(notelink_pairs(fixture)).to be_nil
    expect(redock_output(fixture).first).to eq(["M 310 730 L 830 643"])
  end

  it "preserves diagonal Association and Dependency geometric edges" do
    %w[Association Dependency].each do |type|
      expect(notelink_pairs(notelink_fixture(type: type))).to eq([[310, 714], [450, 684]])
    end
  end
end
