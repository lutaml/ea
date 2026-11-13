# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.shared_context "text svg fixture" do
  def svg_with_texts(texts)
    body = texts.map do |(x, y, family, size, content)|
      %(<g style="fill:#000000;"><text x="#{x}" y="#{y}" ) +
        %(textLength="10" style="font-family:#{family}; font-size:#{size}" ) +
        %(xml:space="preserve">#{content}</text></g>)
    end.join
    "<svg viewBox=\"0 0 400 300\">#{body}</svg>"
  end
end

RSpec.describe Ea::Svg::Parity::Differ, "connector endpoints" do
  it "reports a source on the wrong box edge despite a matching centroid" do
    ref = <<~SVG
      <svg><g><rect x="0" y="0" width="10" height="10"/>
      <path d="M 10 5 L 50 5 L 100 5"/></g></svg>
    SVG
    ours = ref.sub("M 10 5", "M 5 0")
    differ = described_class.new(ours: ours, reference: ref)
    delta = differ.connector_deltas.first

    expect(delta[:source_delta]).to be > described_class::EPSILON
    expect(delta[:source_delta]).to be_within(0.001).of(Math.sqrt(50))
    expect(delta[:target_delta]).to eq(0.0)
    expect(delta[:ours]).to eq(differ.ours.last)
    expect(delta[:reference]).to eq(differ.reference.last)
    expect(described_class.new(ours: ref, reference: ref).connector_deltas.first[:source_delta]).to eq(0.0)
  end
end

RSpec.describe Ea::Svg::Parity::Differ, "connector endpoints" do
  it "corrects both endpoints of paths and lines by the dominant shift" do
    ours = <<~SVG
      <svg><g><text x="0" y="0">anchor</text><path d="M 10 5 L 100 5"/>
      <line x1="10" y1="50" x2="100" y2="50"/></g></svg>
    SVG
    ref = <<~SVG
      <svg><g><text x="20" y="30">anchor</text><path d="M 30 35 L 120 35"/>
      <line x1="30" y1="80" x2="120" y2="80"/></g></svg>
    SVG
    differ = described_class.new(ours: ours, reference: ref)
    deltas = differ.connector_deltas

    expect(deltas.map { |delta| delta[:kind] }).to eq(%i[path line])
    expect(deltas.map { |delta| delta.values_at(:source_delta, :target_delta) }).to eq([[0.0, 0.0], [0.0, 0.0]])
    expect(differ.connector_deltas).to eq(deltas)
    expect(differ.shape_summary[:matched]).to eq(2)
  end
end

RSpec.describe Ea::Svg::Parity::Differ, "connector endpoints" do
  it "reports target movement for a line" do
    ref = '<svg><g><line x1="10" y1="10" x2="100" y2="10"/></g></svg>'
    ours = ref.sub('x2="100"', 'x2="104"')
    delta = described_class.new(ours: ours, reference: ref).connector_deltas.first

    expect(delta.values_at(:source_delta, :target_delta)).to eq([0.0, 4.0])
    expect(delta[:arrowhead_deltas]).to be_empty
  end
end

RSpec.describe Ea::Svg::Parity::Differ, "connector endpoints" do
  it "excludes closed, empty, single-point and unmatched paths" do
    ours = <<~SVG
      <svg><g><path d="M 0 0 L 10 0 Z"/><path d="M 0 0 L 10 0 z"/>
      <path d=""/><path d="M 0 0"/><path d="M 500 500 L 600 500"/></g></svg>
    SVG
    ref = ours.sub("M 500 500 L 600 500", "M 900 900 L 1000 900")

    expect(described_class.new(ours: ours, reference: ref).connector_deltas).to be_empty
  end
end

RSpec.shared_context "connector arrowhead fixture" do
  let(:reference) do
    '<svg><g><path d="M 0 0 L 100 0"/><polygon points="100,0 90,-5 90,5"/></g></svg>'
  end
end

RSpec.describe Ea::Svg::Parity::Differ, "connector arrowheads" do
  include_context "connector arrowhead fixture"

  it "reports a tip moved off the target endpoint" do
    ours = reference.sub("100,0 90,-5 90,5", "104,0 94,-5 94,5")
    differ = described_class.new(ours: ours, reference: reference)
    delta = differ.connector_deltas.first

    expect(delta.values_at(:source_delta, :target_delta)).to eq([0.0, 0.0])
    expected = [{ end: :target, ours: differ.ours.last, reference: differ.reference.last, tip_delta: 4.0 }]
    expect(delta[:arrowhead_deltas]).to eq(expected)
  end
end

RSpec.describe Ea::Svg::Parity::Differ, "connector arrowheads" do
  include_context "connector arrowhead fixture"

  it "reports zero for a correctly placed tip after the dominant shift" do
    ours = <<~SVG
      <svg><g><text x="0" y="0">anchor</text><path d="M 0 0 L 100 0"/>
      <polygon points="100,0 90,-5 90,5"/></g></svg>
    SVG
    ref = <<~SVG
      <svg><g><text x="20" y="30">anchor</text><path d="M 20 30 L 120 30"/>
      <polygon points="120,30 110,25 110,35"/></g></svg>
    SVG
    delta = described_class.new(ours: ours, reference: ref).connector_deltas.first

    expect(delta[:arrowhead_deltas].map { |arrow| arrow[:tip_delta] }).to eq([0.0])
  end
end

RSpec.describe Ea::Svg::Parity::Differ, "connector arrowheads" do
  include_context "connector arrowhead fixture"

  it "associates arrowheads with the source as well as the target" do
    ref = reference.sub("100,0 90,-5 90,5", "10,-5 0,0 10,5")
    ours = ref.sub("10,-5 0,0 10,5", "10,-1 0,4 10,9")
    delta = described_class.new(ours: ours, reference: ref).connector_deltas.first

    expect(delta[:arrowhead_deltas]).to contain_exactly(include(end: :source, tip_delta: 4.0))
  end
end

RSpec.describe Ea::Svg::Parity::Differ, "connector arrowheads" do
  include_context "connector arrowhead fixture"

  it "reports an unpaired arrowhead instead of losing its placement error" do
    ours = reference.sub("100,0 90,-5 90,5", "150,0 140,-5 140,5")
    delta = described_class.new(ours: ours, reference: reference).connector_deltas.first

    expect(delta[:arrowhead_deltas]).to contain_exactly(
      include(end: :target, ours: nil, tip_delta: Float::INFINITY)
    )
  end
end

RSpec.describe Ea::Svg::Parity::Differ, "connector arrowheads" do
  it "keeps each arrowhead with its connector when polygon order differs" do
    ref = <<~SVG
      <svg><g><path d="M 0 0 L 100 0"/><path d="M 0 50 L 100 50"/>
      <polygon points="100,0 90,-5 90,5"/><polygon points="100,50 90,45 90,55"/></g></svg>
    SVG
    ours = <<~SVG
      <svg><g><path d="M 0 0 L 100 0"/><path d="M 0 50 L 100 50"/>
      <polygon points="104,50 94,45 94,55"/><polygon points="100,0 90,-5 90,5"/></g></svg>
    SVG
    deltas = described_class.new(ours: ours, reference: ref).connector_deltas

    expect(deltas.map { |delta| delta[:arrowhead_deltas].map { |arrow| arrow[:tip_delta] } }).to eq([[0.0], [4.0]])
  end
end

RSpec.describe Ea::Svg::Parity::Differ, "connector arrowheads" do
  include_context "connector arrowhead fixture"

  it "reports an extra arrowhead touching only our endpoint" do
    ref = '<svg><g><path d="M 0 0 L 100 0"/></g></svg>'
    delta = described_class.new(ours: reference, reference: ref).connector_deltas.first

    expect(delta[:arrowhead_deltas]).to contain_exactly(
      include(end: :target, reference: nil, tip_delta: Float::INFINITY)
    )
  end
end

RSpec.describe Ea::Svg::Parity::Differ do
  include_context "text svg fixture"

  it "pairs texts on content and reports position deltas" do
    ours = svg_with_texts([[10, 20, "Arial", "9pt", "name: String"],
                           [30, 40, "Arial", "9pt", "moved out"]])
    ref = svg_with_texts([[10, 20, "Arial", "9pt", "name: String"],
                          [30, 200, "Arial", "9pt", "moved out"]])
    deltas = described_class.new(ours: ours, reference: ref).text_deltas
    expect(deltas[:moved_text].map { |t| t[:content] }).to eq(["moved out"])
    expect(deltas[:missing_text]).to be_empty
    expect(deltas[:extra_text]).to be_empty
  end
end

RSpec.describe Ea::Svg::Parity::Differ do
  include_context "text svg fixture"

  it "reports font family and size mismatches per text" do
    ours = svg_with_texts([[10, 20, "Arial", "9pt", "label"]])
    ref = svg_with_texts([[10, 20, "Carlito", "7pt", "label"]])
    deltas = described_class.new(ours: ours, reference: ref).text_deltas
    expect(deltas[:wrong_font].size).to eq(1)
    expect(deltas[:wrong_size].size).to eq(1)
  end
end

RSpec.describe Ea::Svg::Parity::Differ do
  include_context "text svg fixture"

  it "reports texts missing from ours and extra in ours" do
    ours = svg_with_texts([[10, 20, "Arial", "9pt", "only ours"]])
    ref = svg_with_texts([[10, 20, "Arial", "9pt", "only ref"]])
    deltas = described_class.new(ours: ours, reference: ref).text_deltas
    expect(deltas[:extra_text].map { |t| t[:content] }).to eq(["only ours"])
    expect(deltas[:missing_text].map { |t| t[:content] }).to eq(["only ref"])
  end
end

RSpec.describe Ea::Svg::Parity::Differ do
  include_context "text svg fixture"

  it "normalizes EA's font-weight 0 to 400" do
    ours = svg_with_texts([[10, 20, "Arial", "9pt", "t"]])
    ref_body = <<~SVG
      <svg viewBox="0 0 400 300"><g><text x="10" y="20" style="font-family:Arial; font-weight:0; font-size:9pt">t</text></g></svg>
    SVG
    deltas = described_class.new(ours: ours, reference: ref_body).text_deltas
    expect(deltas[:wrong_weight]).to be_empty
  end
end

RSpec.describe Ea::Svg::Parity::Differ do
  it "summarizes shape matches by centroid proximity" do
    ours = <<~SVG
      <svg viewBox="0 0 400 300"><g><rect x="10" y="10" width="100" height="50"/></g><g><path d="M 200 200 L 300 200"/></g></svg>
    SVG
    ref = <<~SVG
      <svg viewBox="0 0 400 300"><g><rect x="10" y="210" width="100" height="50"/></g><g><path d="M 202 198 L 302 198"/></g></svg>
    SVG
    summary = described_class.new(ours: ours, reference: ref).shape_summary
    expect(summary[:matched]).to eq(1)
    expect(summary[:missing]).to eq(1)
    expect(summary[:extra]).to eq(1)
  end
end

RSpec.describe Ea::Svg::Parity::Differ do
  it "reports rect geometry deltas for centroid-matched shapes" do
    ours = '<svg><g><rect x="13" y="23" width="102" height="52"/></g></svg>'
    ref = '<svg><g><rect x="10" y="20" width="100" height="50"/></g></svg>'
    differ = described_class.new(ours: ours, reference: ref)
    expected = [{ kind: :rect, ours: differ.ours.first, reference: differ.reference.first,
                  dx: 3.0, dy: 3.0, dwidth: 2.0, dheight: 2.0 }]

    expect(differ.shape_deltas).to eq(expected)
  end
end

RSpec.describe Ea::Svg::Parity::Differ do
  it "reports zero rect and polygon deltas for identical shapes" do
    rect = '<g><rect x="10" y="20" width="30" height="40"/></g>'
    polygon = '<g><polygon points="0,0 10,0 10,10"/></g>'
    svg = "<svg>#{rect}#{polygon}</svg>"
    deltas = described_class.new(ours: svg, reference: svg).shape_deltas

    expect(deltas.map { |delta| delta[:kind] }).to eq(%i[rect polygon])
    expect(deltas.first.slice(:dx, :dy, :dwidth, :dheight)).to eq(
      dx: 0.0, dy: 0.0, dwidth: 0.0, dheight: 0.0
    )
    expect(deltas.last[:max_point_delta]).to eq(0.0)
  end
end

RSpec.describe Ea::Svg::Parity::Differ do
  it "corrects shape positions using the text anchor shift" do
    ours = <<~SVG
      <svg><g><text x="20" y="30">anchor</text><rect x="10" y="20" width="10" height="10"/>
      <polygon points="0,0 10,0 10,10"/></g></svg>
    SVG
    ref = <<~SVG
      <svg><g><text x="120" y="80">anchor</text><rect x="110" y="70" width="10" height="10"/>
      <polygon points="100,50 110,50 110,60"/></g></svg>
    SVG
    differ = described_class.new(ours: ours, reference: ref)
    delta = differ.shape_deltas.first

    expect(differ.shape_deltas.last[:max_point_delta]).to eq(0.0)
    expect(delta[:ours]).to eq(differ.ours[1])
    expect(delta[:reference]).to eq(differ.reference[1])
    expect(delta.slice(:dx, :dy, :dwidth, :dheight)).to eq(
      dx: 0.0, dy: 0.0, dwidth: 0.0, dheight: 0.0
    )
  end
end

RSpec.describe Ea::Svg::Parity::Differ do
  it "preserves negative signed rect deltas" do
    ours = '<svg><g><rect x="10" y="20" width="30" height="40"/></g></svg>'
    ref = '<svg><g><rect x="13" y="23" width="32" height="42"/></g></svg>'
    delta = described_class.new(ours: ours, reference: ref).shape_deltas.first

    expect(delta.slice(:dx, :dy, :dwidth, :dheight)).to eq(
      dx: -3.0, dy: -3.0, dwidth: -2.0, dheight: -2.0
    )
  end
end

RSpec.describe Ea::Svg::Parity::Differ do
  it "reports the maximum corresponding polygon point distance" do
    ours = '<svg><g><polygon points="3,4 10,0 10,10"/></g></svg>'
    ref = '<svg><g><polygon points="0,0 10,0 10,10"/></g></svg>'
    delta = described_class.new(ours: ours, reference: ref).shape_deltas.first

    expect(delta[:max_point_delta]).to eq(5.0)
  end
end

RSpec.describe Ea::Svg::Parity::Differ do
  it "reports infinite delta for different polygon point counts and zero for empty polygons" do
    ours = '<svg><g><polygon points="0,0 10,0 10,10"/><polygon points=""/></g></svg>'
    ref = '<svg><g><polygon points="0,0 10,0"/><polygon points=""/></g></svg>'
    deltas = described_class.new(ours: ours, reference: ref).shape_deltas

    expect(deltas.map { |delta| delta[:max_point_delta] }).to eq([Float::INFINITY, 0.0])
  end
end

RSpec.describe Ea::Svg::Parity::Differ do
  it "excludes unmatched shapes and keeps path and line summary counts" do
    ours = <<~SVG
      <svg><g><rect x="10" y="10" width="10" height="10"/><path d="M 0 0 L 10 10"/>
      <line x1="20" y1="20" x2="30" y2="30"/><polygon points="100,100 110,100 110,110"/></g></svg>
    SVG
    ref = <<~SVG
      <svg><g><rect x="10" y="10" width="10" height="10"/><path d="M 0 0 L 10 10"/>
      <line x1="20" y1="20" x2="30" y2="30"/></g></svg>
    SVG
    differ = described_class.new(ours: ours, reference: ref)
    summary = differ.shape_summary

    expect(differ.shape_deltas.map { |delta| delta[:kind] }).to eq([:rect])
    expect(summary).to eq(our_shapes: 4, ref_shapes: 3, matched: 3, missing: 0, extra: 1)
  end
end
