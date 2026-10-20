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
                      [["58.00", "443.00"], ["49.00", "443.00"], ["249.00", "447.00"]],
                      [["205.00", "443.00"], ["196.00", "449.00"], ["262.00", "427.00"]]
                    ])
  end
end
