# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/text_renderer"
require "ea/svg/ea_emitter/element/header_renderer"
require "ea/svg/ea_emitter/render_context"
require "ea/svg/ea_emitter/compartment"
require "ea/svg/ea_emitter/compartment/instance_underline"
require_relative "../../../../support/instance_underline_geometry_helpers"

RSpec.describe Ea::Svg::EaEmitter::Compartment::InstanceUnderline do
  include InstanceUnderlineGeometryHelpers

  let(:bounds) { Ea::Model::Bounds.new(x: 50, y: 40, width: 90, height: 50) }
  let(:theme) { Ea::Theme::Registry.default }
  let(:geometry) do
    Struct.new(:header_first_y, keyword_init: true).new(header_first_y: 59)
  end

  it "matches the final emitted header line's x, textLength, and baseline" do
    [
      [["Object A", :bold]],
      [["«role»", :italic], ["Object 03: Class A", :bold]],
      [["Object 02", :normal], ["Class A", :bold_italic]]
    ].each do |header_lines|
      context = context_for(header_lines)
      rendered_header = Ea::Svg::EaEmitter::Element::HeaderRenderer.render(
        header_lines, bounds: bounds, first_y: geometry.header_first_y,
                      family: context.family, size: context.size, size_unit: context.size_unit,
                      logical_height: context.logical_height,
                      weight_normal: theme.text_weight_normal, weight_bold: theme.text_weight_bold,
                      width_factor: theme.text_width_factor,
                      line_offset: theme.compartments.header_line_offset
      )
      header = rendered_header.scan(/<text x="([^"]+)" y="([^"]+)" textLength="([^"]+)"/).last
      underline = described_class.render(context).match(/<path d="M ([^ ]+) ([^ ]+) L ([^ ]+) ([^ ]+)"/)

      expect(underline).not_to be_nil
      expected = [header[0].to_f, header[1].to_f + 1,
                  header[0].to_f + header[2].to_i, header[1].to_f + 1]
      expect(underline.captures.map(&:to_f)).to eq(expected)
    end
  end

  it "does not underline an empty final header line" do
    expect(described_class.render(context_for([["Object A", :bold], ["", :bold]]))).to be_nil
  end
end
