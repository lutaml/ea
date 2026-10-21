# frozen_string_literal: true

require "spec_helper"

RSpec.describe "0BE UMLDI boundedBy source-role labels" do
  it "uses the three source bounds when EA extension label boxes are absent" do
    expect(Xmi0beBoundedByLabelsHelpers.result(
             fixtures_path("issue135_route_style/0be-boundedby-umldi.xmi")
           )).to eq([
                      [
                        { source_role: { x: 724, y: 1356, width: 57, height: 25 },
                          source_multiplicity: { x: 843, y: 1356, width: 15, height: 13 } },
                        { source_role: { x: 715, y: 1356, width: 57, height: 25 },
                          source_multiplicity: { x: 834, y: 1356, width: 15, height: 13 } },
                        { source_role: { x: 915, y: 1360, width: 57, height: 25 },
                          source_multiplicity: { x: 915, y: 1382, width: 15, height: 13 } }
                      ],
                      [{}, {}, {}],
                      [["58.00", "443.00"], ["49.00", "443.00"], ["249.00", "447.00"]]
                    ])
  end
end

# Genuinely bounds-less source: the fixture above minus its six UMLDI label
# elements (plateau type definitions kept so class widths match). The seats
# are the QEA phantom seats (native position + canvas offset).
RSpec.describe "0BE boundedBy source-role labels" do
  describe "without any UMLDI label bounds" do
    let(:path) { fixtures_path("issue135_route_style/0be-boundedby-bounds-less.xmi") }
    let(:source) { Xmi0beBoundedByLabelsHelpers.source(path) }

    it "carries no label bounds and only zero-offset label boxes" do
      zero = { llb: { "ox" => 0, "oy" => 0 }, llt: { "ox" => 0, "oy" => 0 } }
      expect(source.last.map { |connector| [connector.umldi_label_bounds, connector.label_boxes] })
        .to eq([[{}, zero]] * 3)
    end

    it "seats the three +boundedBy roles at the QEA phantom positions" do
      expect(Xmi0beBoundedByLabelsHelpers.render_texts(*source, "+boundedBy"))
        .to eq([["58.00", "443.00"], ["49.00", "443.00"], ["249.00", "447.00"]])
    end

    it "seats their 0..* multiplicities at the QEA phantom positions" do
      expect(Xmi0beBoundedByLabelsHelpers.render_texts(*source, "0..*"))
        .to include(["177.00", "443.00"], ["168.00", "443.00"], ["249.00", "469.00"])
    end
  end
end
