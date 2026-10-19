# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "keeps the default square source flush with the target ray height" do
    cases = [
      [[512, 494, 347, 326], [73, 558, 224, 108], "M 474 168 L 260 168",
       "474 168 464 173 454 168 464 163"],
      [[450, 361, 347, 326], [11, 461, 224, 108], "M 474 196 L 260 196",
       "474 196 464 201 454 196 464 191"]
    ]
    cases.each do |source, target, path, diamond|
      result = render_qea_route(source: source, target: target, geometry: "EX=0;EY=0;EDGE=4;",
                                style: "Mode=3;TREE=OS;LWidth=2;", path: nil,
                                connector_type: "Aggregation")
      expect(result).to eq(paths: [path], markers: [diamond])
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:default_square) do
    { connector_type: "Aggregation", source: [512, 494, 347, 326], target: [73, 558, 224, 108],
      geometry: "EX=0;EY=0;EDGE=4;", path: nil, style: "Mode=3;TREE=OS;LWidth=2;" }
  end

  it "preserves explicit offsets, other routing modes and authored paths" do
    controls = [
      { geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=4;" },
      { style: "Mode=2;TREE=OS;LWidth=2;" }, { style: "Mode=3;TREE=V;LWidth=2;" },
      { path: "480:-657;350:-612;" }, { geometry: "EX=1;EY=0;EDGE=4;" },
      { geometry: "EX=0;EY=1;EDGE=4;" }
    ]
    controls.each do |changes|
      result = render_qea_route(**default_square.merge(changes))
      expect(result).to eq(paths: ["M 473 187 L 260 168"],
                           markers: ["473 187 463 191 453 185 463 181"])
    end
  end

  it "preserves thin square connector routing" do
    %w[0 1].each do |width|
      result = render_qea_route(**default_square.merge(style: "Mode=3;TREE=OS;LWidth=#{width};"))
      expect(result).to eq(paths: ["M 474 187 L 259 168"],
                           markers: ["474 187 464 191 454 185 464 181"])
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "retains legacy rendering without the QEA default-square producer flag" do
    result = render_qea_route(connector_type: "Aggregation", source: [512, 494, 347, 326],
                              target: [73, 558, 224, 108], geometry: "EX=0;EY=0;EDGE=4;",
                              path: nil, style: "Mode=3;TREE=OS;LWidth=2;") do |document|
      document.diagrams.first.connectors.first.style.delete(:default_square_ray)
    end

    expect(result).to eq(paths: ["M 473 187 L 260 168"],
                         markers: ["473 187 463 191 453 185 463 181"])
  end
end
