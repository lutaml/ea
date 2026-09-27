# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::Parity::Differ do
  def svg_with_texts(texts)
    body = texts.map do |(x, y, family, size, content)|
      %(<g style="fill:#000000;"><text x="#{x}" y="#{y}" textLength="10" style="font-family:#{family}; font-size:#{size}" xml:space="preserve">#{content}</text></g>)
    end.join
    "<svg viewBox=\"0 0 400 300\">#{body}</svg>"
  end

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

  it "reports font family and size mismatches per text" do
    ours = svg_with_texts([[10, 20, "Arial", "9pt", "label"]])
    ref = svg_with_texts([[10, 20, "Carlito", "7pt", "label"]])
    deltas = described_class.new(ours: ours, reference: ref).text_deltas
    expect(deltas[:wrong_font].size).to eq(1)
    expect(deltas[:wrong_size].size).to eq(1)
  end

  it "reports texts missing from ours and extra in ours" do
    ours = svg_with_texts([[10, 20, "Arial", "9pt", "only ours"]])
    ref = svg_with_texts([[10, 20, "Arial", "9pt", "only ref"]])
    deltas = described_class.new(ours: ours, reference: ref).text_deltas
    expect(deltas[:extra_text].map { |t| t[:content] }).to eq(["only ours"])
    expect(deltas[:missing_text].map { |t| t[:content] }).to eq(["only ref"])
  end

  it "normalizes EA's font-weight 0 to 400" do
    ours = svg_with_texts([[10, 20, "Arial", "9pt", "t"]])
    ref_body = <<~SVG
      <svg viewBox="0 0 400 300"><g><text x="10" y="20" style="font-family:Arial; font-weight:0; font-size:9pt">t</text></g></svg>
    SVG
    deltas = described_class.new(ours: ours, reference: ref_body).text_deltas
    expect(deltas[:wrong_weight]).to be_empty
  end

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
