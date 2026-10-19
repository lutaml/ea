# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../support/c198_target_multiplicity_helpers"

RSpec.describe "C198 exact target dock multiplicity seat" do
  include C198TargetMultiplicityHelpers

  it "uses the existing left target multiplicity seat from a certified interior face" do
    expect(c198_target_face).to eq([-1, 0])

    positions = c198_target_multiplicity

    expect(positions.fetch("1")).to eq([610.0, 523.0])
  end

  it "leaves role and stereotype positions unchanged" do
    with_face = c198_target_multiplicity
    without_face = c198_target_multiplicity(target_face: nil)

    expect(with_face.fetch("+member")).to eq(without_face.fetch("+member"))
    expect(with_face.fetch("«property»")).to eq(without_face.fetch("«property»"))
  end
end

RSpec.describe "C198 target multiplicity guard preservation" do
  include C198TargetMultiplicityHelpers

  it "preserves moved multiplicities and unsupported presentation" do
    moved = c198_target_multiplicity(mult_box: { "ox" => 9 })
    plain = c198_target_multiplicity(stereotype: nil)
    bold = c198_target_multiplicity(mult_box: { "bold" => true })
    other_font = c198_target_multiplicity(font: { family: "Arial" })
    other_size = c198_target_multiplicity(font: { size: 8 })
    other_unit = c198_target_multiplicity(font: { unit: "px" })
    legacy_heading = c198_target_multiplicity(target_face: nil, heading: [-215, 0])

    expect(moved.fetch("1")).to eq([628.0, 508.0])
    expect(plain.fetch("1")).to eq([631.0, 523.0])
    expect(bold.fetch("1")).to eq([631.0, 523.0])
    expect(other_font.fetch("1")).to eq([631.0, 523.0])
    expect(other_size.fetch("1")).to eq([631.0, 523.0])
    expect(other_unit.fetch("1")).to eq([631.0, 523.0])
    expect(legacy_heading.fetch("1")).to eq([610.0, 523.0])
  end

  it "rejects a nonface or ambiguous corner" do
    nonface = c198_target_face(target_box: Ea::Model::Bounds.new(x: 618, y: 451, width: 194, height: 91))
    corner = c198_target_face(point: [619, 451])

    expect(nonface).to be_nil
    expect(corner).to be_nil
  end
end
