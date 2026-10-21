# frozen_string_literal: true

require "spec_helper"

RSpec.shared_context "XMI Generalization saved ray" do
  subject(:metadata) do
    Ea::Sources::Xmi::StoredRoute.new.ray_metadata(model, link: link, bounds: bounds,
                                                          offsets: offsets, edge: edge)
  end

  # 22C24D4C / 471BF2F9: Square to TransportationComplex.
  let(:bounds) do
    { source: Ea::Model::Bounds.new(x: 618, y: 402, width: 120, height: 80),
      target: Ea::Model::Bounds.new(x: 588, y: 230, width: 202, height: 117) }
  end
  let(:style) { { mode: "1", lwidth: "2", custom: "preserved" } }
  let(:path) { "641:-274;671:-274;" }
  let(:link) { Ea::Sources::Xmi::StoredRoute::Link.new("Mode=#{style[:mode]};LWidth=2;", path) }
  let(:offsets) { { source: [9, 4], target: [-2, 6] } }
  let(:edge) { 1 }
  let(:connector_type) { "Generalization" }
  let(:waypoints) do
    [[738, 415], [670, 230]].map do |x, y|
      Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y))
    end
  end
  let(:model) do
    Ea::Model::DiagramConnector.new(connector_type: connector_type, waypoints: waypoints, style: style)
  end
end

RSpec.shared_context "XMI Generalization placed ray" do
  before do
    described_class.new(nil).send(:mark_stored_ray, model, placed_connector,
                                  placements[:source], placements[:target])
  end

  let(:placements) do
    bounds.transform_values do |box|
      Ea::Sources::Xmi::ExtensionElements::PlacedElement.new(
        geometry: Ea::Sources::Xmi::ExtensionGeometryParser.parse(
          "Left=#{box.x};Top=#{box.y};Right=#{box.x + box.width};Bottom=#{box.y + box.height};"
        )
      )
    end
  end
  let(:placed_connector) do
    Ea::Sources::Xmi::ExtensionElements::PlacedConnector.new(
      geometry: Ea::Sources::Xmi::ExtensionGeometryParser.parse("SX=9;SY=4;EX=-2;EY=6;EDGE=1;Path=#{path};"),
      style: Ea::Sources::Xmi::ExtensionStyleParser.parse(link.style)
    )
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  it "retains 22C24D4C / 471BF2F9 mathematical origins, ports, geometry and centered classification" do
    expect(metadata).to include(has_geometry_offsets: true, style: style.merge(centered_origin_ray: true))
    expect(metadata[:source_anchor]).to have_attributes(x: 687, y: 438)
    expect(metadata[:target_anchor]).to have_attributes(x: 687, y: 282)
    expect(metadata[:source_port]).to have_attributes(x: 738, y: 415)
    expect(metadata[:target_port]).to have_attributes(x: 670, y: 230)
    expect(model.style.to_h).to eq(style)
    expect(model.source_anchor).to be_nil
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with Mode 1 and empty Path" do
    let(:path) { "" }

    it("still retains the saved origins") { expect(metadata[:source_anchor]).to have_attributes(x: 687, y: 438) }
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with Mode 3 and empty Path" do
    let(:style) { super().merge(mode: "3") }
    let(:path) { "" }

    it "certifies both centered and stored origins" do
      expect(metadata[:style]).to eq(style.merge(centered_origin_ray: true, stored_origin_ray: true))
      expect(metadata[:source_anchor]).to have_attributes(x: 687, y: 438)
      expect(metadata[:target_port]).to have_attributes(x: 670, y: 230)
    end
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with an authored Path" do
    let(:style) { super().merge(mode: "3") }
    let(:path) { "641:-274;" }

    it("preserves authored routing") { expect(metadata).to eq({}) }
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with an incompatible edge" do
    let(:style) { super().merge(mode: "3") }
    let(:path) { "" }
    let(:edge) { 4 }

    it("rejects a gap on the wrong axis") { expect(metadata).to eq({}) }
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with regenerated style" do
    let(:style) { super().merge(mode: "3", regenerated: true) }
    let(:path) { "" }

    it "keeps centered classification without stored custom-line classification" do
      expect(metadata[:style]).to eq(style.merge(centered_origin_ray: true))
    end
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with TREE" do
    let(:style) { super().merge(tree: "V") }

    it("preserves tree routing") { expect(metadata).to eq({}) }
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with Mode 2" do
    let(:style) { super().merge(mode: "2") }

    it("preserves orthogonal routing") { expect(metadata).to eq({}) }
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with a bent route" do
    let(:waypoints) { super() + [super().last] }

    it("preserves the bend") { expect(metadata).to eq({}) }
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with missing source offset" do
    let(:offsets) { { source: [nil, 4], target: [-2, 6] } }

    it("does not invent geometry") { expect(metadata).to eq({}) }
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with missing target offset" do
    let(:offsets) { { source: [9, 4], target: [-2, nil] } }

    it("does not invent geometry") { expect(metadata).to eq({}) }
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with zero vertical offsets" do
    let(:offsets) { { source: [9, 0], target: [-2, 0] } }

    it("keeps the existing geometry") { expect(metadata).to eq({}) }
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with a zero source vector" do
    let(:offsets) { { source: [0, 0], target: [-2, 6] } }

    it("does not invent an explicit source port") { expect(metadata).to eq({}) }
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with a missing endpoint box" do
    let(:bounds) { super().merge(target: nil) }

    it("does not invent an origin") { expect(metadata).to eq({}) }
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with overlapping boxes" do
    let(:bounds) { super().merge(target: super()[:source]) }

    it("does not classify a gap ray") { expect(metadata).to eq({}) }
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with an origin on the grown outline" do
    let(:offsets) { { source: [61, 4], target: [-2, 6] } }

    it("certifies the one-pixel outline allowance") { expect(metadata[:style]).to include(centered_origin_ray: true) }
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with an origin beyond the grown outline" do
    let(:offsets) { { source: [62, 4], target: [-2, 6] } }

    it "retains origins without certifying centered clipping" do
      expect(metadata[:source_anchor]).to have_attributes(x: 740, y: 438)
      expect(metadata[:style]).to eq(style)
    end
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  context "with a thin line" do
    let(:style) { super().merge(lwidth: "0") }

    it "retains origins without width-2 classification" do
      expect(metadata[:source_anchor]).to have_attributes(x: 687, y: 438)
      expect(metadata[:style]).to eq(style)
    end
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Generalization saved ray metadata" do
  include_context "XMI Generalization saved ray"

  %w[Association Aggregation].each do |type|
    context "with #{type}" do
      let(:connector_type) { type }

      it "preserves the prior direct ray metadata without Generalization style flags" do
        expect(metadata.keys).to contain_exactly(:source_port, :target_port, :source_anchor,
                                                 :target_anchor, :has_geometry_offsets)
        expect(metadata[:source_anchor]).to have_attributes(x: 687, y: 438)
        expect(metadata[:target_anchor]).to have_attributes(x: 687, y: 282)
        expect(metadata[:source_port]).to have_attributes(x: 738, y: 415)
        expect(metadata[:target_port]).to have_attributes(x: 670, y: 230)
      end
    end
  end
end

RSpec.describe Ea::Sources::Xmi::DiagramBuilder, "Generalization ray classification" do
  include_context "XMI Generalization saved ray"
  include_context "XMI Generalization placed ray"

  it "attaches origins and ports without assigning an Association outline" do
    expect(model.source_anchor).to have_attributes(x: 687, y: 438)
    expect(model.target_anchor).to have_attributes(x: 687, y: 282)
    expect(model.source_port).to have_attributes(x: 738, y: 415)
    expect(model.target_port).to have_attributes(x: 670, y: 230)
    expect(model.has_geometry_offsets).to be(true)
    expect(model.style.to_h).to eq(style.merge(centered_origin_ray: true))
  end

  context "with UMLDI geometry" do
    let(:style) { super().merge(umldi_route: true) }

    it "leaves UMLDI authoritative" do
      expect(model.source_anchor).to be_nil
      expect(model.source_port).to be_nil
      expect(model.style.to_h).to eq(style)
    end
  end
end

RSpec.describe Ea::Sources::Xmi::DiagramBuilder, "saved Association ray preservation" do
  include_context "XMI Generalization saved ray"
  include_context "XMI Generalization placed ray"

  %w[Association Aggregation].each do |type|
    context "with #{type}" do
      let(:connector_type) { type }

      it "preserves the existing outline classification" do
        expect(model.style.to_h).to eq(style.merge(association_ray_outline: true))
        expect(model.source_anchor).to have_attributes(x: 687, y: 438)
        expect(model.target_port).to have_attributes(x: 670, y: 230)
      end
    end
  end
end
