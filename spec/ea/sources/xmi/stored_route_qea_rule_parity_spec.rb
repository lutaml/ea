# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Mode 2 Generalization horizontal-jog Path (FEAE013A)" do
  include XmiRouteSliceHelpers

  subject(:metadata) do
    run_stage(:ray_metadata, slice(type: "Generalization", style: { mode: "2", lwidth: "2" },
                                   link_style: "Mode=2;EOID=1BD342D7;SOID=4DDACBC9;Color=-1;LWidth=2;Hidden=0;",
                                   path: "583:-629;598:-629;", boxes: [[851, 932, 269, 309], [860, 641, 216, 241]],
                                   offsets: [[3, 66], [-48, 91]], edge: 1,
                                   waypoints: [[851, 931], [583, 629], [598, 629], [860, 882]]))
  end

  it "replaces the stored bends with one vertical ray, as QEA does" do
    expect(metadata[:waypoints].map { |w| xy(w.position) }).to eq([[971, 931], [971, 883]])
    expect([metadata[:source_anchor], metadata[:target_anchor]].map { |p| xy(p) }).to eq([[971, 1086], [971, 761]])
    expect(metadata[:has_geometry_offsets]).to be(true)
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "Mode 2 Associations through the shared overlap row (348EE46E)" do
  include XmiRouteSliceHelpers

  def route(path:, offsets:, waypoints:)
    run_stage(:association_route,
              slice(type: "Association", style: { mode: "2", lwidth: "2" },
                    link_style: "Mode=2;EOID=46CCCA95;SOID=0CFB50F5;Color=-1;LWidth=2;Hidden=0;", path: path,
                    boxes: [[696, 354, 194, 115], [116, 354, 365, 240]], offsets: offsets, edge: 4,
                    waypoints: waypoints))
  end

  it "gives the first Association QEA's overlap origins and flush ports" do
    metadata = route(path: "358:-940;112:-940;", offsets: [[-34, -40], [-12, -8]], waypoints: [[696, 469], [481, 469]])
    expect(metadata[:waypoints].map { |w| xy(w.position) }).to eq([[793, 451], [298, 451]])
    expect([metadata[:source_port], metadata[:target_port]].map { |p| xy(p) }).to eq([[744, 469], [119, 594]])
    expect(metadata[:style]).to include(overlap_ray: true)
  end

  it "gives the second Association its own row" do
    metadata = route(path: "357:-940;146:-940;", offsets: [[-29, -10], [34, 100]], waypoints: [[696, 445], [481, 445]])
    expect(metadata[:waypoints].map { |w| xy(w.position) }).to eq([[793, 421], [298, 421]])
    expect([metadata[:source_port], metadata[:target_port]].map { |p| xy(p) }).to eq([[696, 445], [339, 354]])
  end
end

# These diagrams regressed when a changed route was detected by comparing with
# model.waypoints instead of the candidate's own initial waypoints.
RSpec.describe Ea::Sources::Xmi::StoredRoute, "authored bends that must be kept" do
  include XmiRouteSliceHelpers

  XmiRouteSliceHelpers::KEPT_BENDS.each do |guid, (type, style, link_style, path, boxes, offsets, edge, waypoints)|
    it "adds no replacement route for #{guid}" do
      args = slice(type: type, style: style, link_style: link_style, path: path, boxes: boxes,
                   offsets: offsets, edge: edge, waypoints: waypoints)
      expect(run_stage(:association_route, args)).to eq({})
    end
  end
end
