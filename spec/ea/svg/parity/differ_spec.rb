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
