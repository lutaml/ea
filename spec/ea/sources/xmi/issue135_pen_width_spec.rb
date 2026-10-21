# frozen_string_literal: true

require "spec_helper"

# Plateau 01661E1B: LWth=-1 over BorderWidth=2 drew 1px (native 2).
# Plateau 1A10EB6D: LWth=0 drew 0px (native 1, the cosmetic pen).
RSpec.describe "XMI element pen width" do
  let(:path) { fixtures_path("issue135_pen_width.xmi") }
  let(:root) { Xmi::Sparx::Root.parse_xml(File.read(path)) }
  let(:diagram) { Ea::Sources::Xmi::DiagramBuilder.new(root, path).build_all.first }

  def width_of(duid)
    diagram.elements.find { |element| element.duid == duid }.line_width
  end

  it "inherits the saved border width when LWth is negative" do
    expect(width_of("00000001")).to eq(2)
  end

  it "requests the one-pixel cosmetic pen for LWth=0, as QEA does" do
    expect(width_of("00000002")).to eq(1)
  end

  it "keeps an explicit positive LWth over the saved border width" do
    expect(width_of("00000003")).to eq(3)
  end
end

# Connector 438 (9400D9BC): LWidth=0 on the link, IsBold=2 on the connector.
# issue135_connector_pen.xmi is stored_bend_end_orientation.xmi with connector
# 63FFF9AA saved that way; connector 2931192E keeps LWidth=2 over linewidth=0.
RSpec.describe "XMI connector pen width" do
  let(:path) { fixtures_path("issue135_connector_pen.xmi") }
  let(:root) { Xmi::Sparx::Root.parse_xml(File.read(path)) }
  let(:connectors) { Ea::Sources::Xmi::DiagramBuilder.new(root, path).build_all.first.connectors }

  def connector(guid)
    connectors.find { |c| c.relationship_ref.to_s.include?(guid) }
  end

  it "carries the connector's own saved pen width" do
    expect([connector("63FFF9AA").line_width, connector("2931192E").line_width]).to eq([2, 0])
  end

  it "strokes a zero-width link with that pen and keeps an explicit link width" do
    widths = %w[63FFF9AA 2931192E].map do |guid|
      Ea::Svg::EaEmitter::Connectors.stroke_width_for(connector(guid), 5)
    end

    expect(widths).to eq([2, 2])
  end
end
