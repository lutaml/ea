# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::ColorResolver, "theme 119 default border" do
  let(:theme) { Ea::Theme::Registry.lookup("119") }
  let(:resolver) { described_class.new(theme: theme) }

  [nil, -1].each do |pen|
    it "uses the native black outline with line color #{pen.inspect}" do
      element = Ea::Model::DiagramElement.new(id: "element", line_color: pen)
      expect(resolver.stroke_for(element)).to eq("#000000")
    end
  end

  it "preserves theme 119 font settings" do
    expect([theme.font_family, theme.font_size, theme.font_size_unit,
            theme.element_font_family, theme.element_font_size, theme.element_font_unit])
      .to eq(["Carlito", 7, "pt", "Cambria", 9, "pt"])
  end
end

RSpec.describe Ea::Svg::EaEmitter::ColorResolver, "explicit border precedence" do
  let(:theme) { Ea::Theme::Registry.lookup("119") }
  let(:resolver) { described_class.new(theme: theme) }

  [[0, "#000000"], [0xFF0000, "#0000FF"]].each do |pen, expected|
    it "preserves explicit line color #{pen}" do
      element = Ea::Model::DiagramElement.new(id: "element", line_color: pen)
      expect(resolver.stroke_for(element)).to eq(expected)
    end
  end

  it "preserves custom theme defaults" do
    custom = theme.with(id: "custom_border", border_color: "#123456")
    element = Ea::Model::DiagramElement.new(id: "element", line_color: -1)
    expect(described_class.new(theme: custom).stroke_for(element)).to eq("#123456")
  end
end

RSpec.describe Ea::Svg::EaEmitter::ColorResolver, "other border defaults" do
  ["39", nil].each do |theme_id|
    it "preserves the black default for theme #{theme_id.inspect}" do
      theme = Ea::Theme::Registry.lookup(theme_id)
      element = Ea::Model::DiagramElement.new(id: "element", line_color: -1)
      expect(described_class.new(theme: theme).stroke_for(element)).to eq("#000000")
    end
  end
end
