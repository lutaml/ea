# frozen_string_literal: true

require "spec_helper"
require "ea/svg/ea_emitter/element/row_icon_renderer"

RSpec.describe Ea::Svg::EaEmitter::Element::RowIconRenderer do
  describe ".render" do
    it "renders a 13x9 folder rect for :package kind" do
      svg = described_class.render(x_pos: 40, y_pos: 80, kind: :package)
      expect(svg).to include("<rect")
      expect(svg).to include('width="13"')
      expect(svg).to include('height="9"')
      expect(svg).not_to include("<path")
    end

    it "renders 2 rects + 7 paths for :default kind" do
      svg = described_class.render(x_pos: 40, y_pos: 80, kind: :default)
      rect_count = svg.scan(/<rect\b/).size
      path_count = svg.scan(/<path\b/).size
      expect(rect_count).to eq(2)
      expect(path_count).to eq(7)
    end

    it "renders 1 rect + 7 paths for :enumeration kind" do
      svg = described_class.render(x_pos: 40, y_pos: 80, kind: :enumeration)
      rect_count = svg.scan(/<rect\b/).size
      path_count = svg.scan(/<path\b/).size
      expect(rect_count).to eq(1)
      expect(path_count).to eq(7)
    end

    it "defaults to :default kind when none specified" do
      svg = described_class.render(x_pos: 40, y_pos: 80)
      expect(svg.scan(/<rect\b/).size).to eq(2)
    end

    it "uses green fill for enumeration icon" do
      svg = described_class.render(x_pos: 40, y_pos: 80, kind: :enumeration)
      expect(svg).to include("#E6FFE1")
    end

    it "uses pale-yellow fill for default icon" do
      svg = described_class.render(x_pos: 40, y_pos: 80, kind: :default)
      expect(svg).to include("#FEFAF5")
    end
  end
end
