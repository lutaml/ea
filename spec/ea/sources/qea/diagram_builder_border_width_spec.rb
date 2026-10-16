# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaBorderWidthHelpers
  include ConnectorRedockHelpers

  it "inherits saved object widths only when the placement uses its default" do
    [["LWth=2;", 4, 2], ["LWth=0;", 4, 0], ["LWth=-1;", 4, 4],
     [nil, 1, 1], ["LWth=-1;", -1, nil], [nil, nil, nil]].each do |style, stored, expected|
      document = border_width_document(placement: style, object_width: stored)
      expect(document.diagrams.first.elements.first.line_width).to eq(expected)
    end
  end

  it "renders explicit widths before the diagram theme and preserves zero" do
    [0, 1, 2, 4].each do |width|
      document = border_width_document(placement: "LWth=#{width};")
      expect(rendered_border_width(document)).to eq(width)
    end
  end
end

RSpec.describe "Inherited element borders" do
  include QeaBorderWidthHelpers

  it "inherits the calibrated white theme border and respects custom themes" do
    document = border_width_document
    diagram = document.diagrams.first
    expect(diagram.theme.stroke_width).to eq(1)
    expect(rendered_border_width(document)).to eq(1)
    diagram.theme = diagram.theme.with(id: "custom_width", element_border_width: 4)
    expect(rendered_border_width(document)).to eq(4)
    diagram.elements.first.line_width = -1
    expect(rendered_border_width(document)).to eq(4)
    expect(Ea::Theme::Registry.default.stroke_width).to eq(2)
    expect(Ea::Theme::Registry.lookup("39").stroke_width).to eq(2)
  end
end

RSpec.describe Ea::Svg::EaEmitter::ConnectorRedock do
  include ConnectorRedockHelpers

  it "docks phantom rays at the resolved border's whole-pixel half width" do
    [0, 1, 2, 4].each do |width|
      fixture = redock_fixture(type: "Association", width: nil, style: { phantom_outline: true })
      fixture[:diagram].elements = %w[s t].map do |ref|
        Ea::Model::DiagramElement.new(model_element_ref: ref, line_width: width)
      end
      inset = width / 2
      expect(redock_output(fixture).first).to eq(["M 20 #{100 - inset} L 20 #{40 + inset}"])
    end
  end

  it "resolves phantom inherited widths through the diagram theme" do
    fixture = redock_fixture(type: "Association", width: nil, style: { phantom_outline: true })
    fixture[:diagram].style_ex = "Theme=:119;"
    fixture[:diagram].elements = %w[s t].map do |ref|
      Ea::Model::DiagramElement.new(model_element_ref: ref, line_width: -1, style: { lwth: "-1" })
    end
    expect(redock_output(fixture).first).to eq(["M 20 100 L 20 40"])
  end
end

RSpec.describe "EA native inherited border docking" do
  include ConnectorRedockHelpers

  it "matches the A081 phantom Association docks with inherited white-theme borders" do
    fixture = redock_fixture(type: "Association", width: nil, anchors: nil,
                             style: { phantom_outline: true }, source: [470, 450, 404, 111],
                             target: [80, 210, 229, 156])
    fixture[:diagram].style_ex = "Theme=:119;"
    fixture[:diagram].elements = %w[s t].map do |ref|
      Ea::Model::DiagramElement.new(model_element_ref: ref, style: { lwth: "-1" })
    end
    expect(redock_output(fixture).first).to eq(["M 550 450 L 309 340"])
  end
end
