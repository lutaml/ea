# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

# rubocop:disable Metrics/BlockLength
RSpec.describe Ea::Svg::EaEmitter::ConnectorRedock do
  include ConnectorRedockHelpers
  include QeaRoutingHelpers
  include ConnectorRedockDependencyHelpers

  # Each relationship names its ends by its own ids; a missing id keeps the
  # stored route whatever boxes sit under the ray origins.
  describe "relationship end ids" do
    let(:boxes) { { source: [600, 220, 133, 80], target: [260, 220, 133, 80] } }
    let(:relationships) do
      {
        "Dependency" => ->(ids) { Ea::Model::Dependency.new(id: "r", client_id: ids[0], supplier_id: ids[1]) },
        "Realization" => ->(ids) { Ea::Model::Realization.new(id: "r", realizing_id: ids[0], contract_id: ids[1]) },
        "Generalization" => ->(ids) { Ea::Model::Generalization.new(id: "r", specific_id: ids[0], general_id: ids[1]) },
        "Association" => ->(ids) { Ea::Model::Association.new(id: "r", source_id: ids[0], target_id: ids[1]) }
      }
    end

    it "clips at the edges of the boxes named by the relationship's own ids" do
      expect(dependency_end_route("Realization", %w[s t])).to eq(["M 600 260 L 393 260"])
      expect(dependency_end_route("Dependency", %w[s t])).to eq(["M 393 260 L 600 260 M 393 260"])
    end

    it "follows the named ends, not the boxes under the anchors" do
      expect(dependency_end_route("Dependency", %w[t s])).to eq(["M 600 260 L 393 260 M 600 260"])
    end

    it "keeps the stored route when an end id is missing, for every type" do
      relationships.each_key do |type|
        expected = type == "Dependency" ? "M 260 260 L 600 260 M 260 260" : "M 600 260 L 260 260"
        [[nil, "t"], ["s", nil], [nil, nil]].each do |ids|
          expect(dependency_end_route(type, ids)).to eq([expected]), "#{type} #{ids}"
        end
      end
    end
  end

  describe "bordered Dependency ends" do
    let(:thin) do
      { connector_type: "Dependency", source: [724, 563, 384, 64],
        target: [761, 1, 312, 465], path: nil, geometry: "EDGE=1;",
        style: "Mode=3;LWidth=0;" }
    end
    let(:bordered) { "NSL=0;LCol=-1;LWth=2;BCol=16764159;" }
    let(:default) { "NSL=0;BCol=-1;BFol=-1;LCol=-1;LWth=-1;" }

    it "stops on the outer edge of 2px element borders like the other thin connectors" do
      expect(render_qea_route(**thin, object_styles: [bordered, bordered])[:paths].first)
        .to eq("M 227 506 L 227 601 M 227 506")
    end

    it "keeps default borders on the geometric edge" do
      expect(render_qea_route(**thin, object_styles: [default, default])[:paths].first)
        .to eq("M 227 505 L 227 602 M 227 505")
    end
  end

  describe "flush tree trunks" do
    it "docks a vertical trunk end stored on the far edge at the facing edge" do
      points = [[165, 274], [165, 230], [371, 230], [371, 100]]

      expect(dependency_trunk_route("V", points, source: [100, 274, 130, 80], target: [306, 100, 130, 80]))
        .to eq(["M 165 274 L 165 230 L 371 230 L 371 180"])
    end

    it "moves a horizontal trunk end stored off-axis onto the facing side at the bend row" do
      points = [[75, 165], [220, 126], [220, 70], [400, 70]]

      expect(dependency_trunk_route("H", points, source: [30, 85, 130, 80], target: [270, 30, 130, 80]))
        .to eq(["M 160 126 L 220 126 L 220 70 L 270 70"])
    end

    it "leaves the builder-routed Generalization trunk on its stored ends" do
      points = [[165, 274], [165, 230], [371, 230], [371, 100]]

      expect(dependency_trunk_route("V", points, source: [100, 274, 130, 80], target: [306, 100, 130, 80],
                                                 type: "Generalization"))
        .to eq(["M 165 274 L 165 230 L 371 230 L 371 100"])
    end

    it "keeps trunks already on the facing edge, outlined, wide, untreed or ambiguous" do
      source = [100, 274, 130, 80]
      target = [306, 100, 130, 80]
      facing = [[165, 274], [165, 230], [371, 230], [371, 180]]
      cases = {
        "end already on the facing edge" => [facing, {}, "M 165 274 L 165 230 L 371 230 L 371 180"],
        "width 2" => [[[165, 274], [165, 230], [371, 230], [371, 100]], { lwidth: "2" },
                      "M 165 274 L 165 230 L 371 230 L 371 100"],
        "no tree" => [[[165, 274], [165, 230], [371, 230], [371, 100]], { tree: nil },
                      "M 165 274 L 165 230 L 371 230 L 371 100"],
        "bend inside the box rows" => [[[165, 274], [165, 230], [371, 150], [371, 100]], {},
                                       "M 165 274 L 165 230 L 371 150 L 371 100"],
        "bend beside the box" => [[[165, 274], [165, 230], [500, 230], [500, 100]], {},
                                  "M 165 274 L 165 230 L 500 230 L 500 100"]
      }

      cases.each do |name, (points, style, expected)|
        expect(dependency_trunk_route(style.fetch(:tree, "V"), points, source: source, target: target,
                                                                       **style.except(:tree))).to eq([expected]), name
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
