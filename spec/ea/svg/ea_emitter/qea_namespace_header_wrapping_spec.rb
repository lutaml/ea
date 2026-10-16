# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "QEA namespace header wrapping" do
  include QeaCompartmentFontHelpers

  let(:document) { public_compartment_document }

  it "matches the published namespace line sequence and preserves separator glyphs", :aggregate_failures do
    {
      "575E87BA-32E9-4a84-AA4E-0EFDFC5D4C07" => ["xs:", "nonNegativeInteger"],
      "ADC8773C-1B27-48ac-BAC1-14C1C919FAF6" => ["wtr::", "WaterGroundSurface"],
      "9994BF62-51E2-42cd-BB35-16C537B6718A" => ["urf::", "HousingControlArea"]
    }.each do |diagram_id, expected|
      texts = compartment_texts(document, diagram_id).map(&:text)

      expect(texts.each_cons(2).to_a).to include(expected)
      expect(texts).not_to include(expected.join)
    end
  end

  it "preserves short qualified names and normal headers in the same diagrams" do
    {
      "575E87BA-32E9-4a84-AA4E-0EFDFC5D4C07" => ["xs:string", "xs:integer", "xs:date"],
      "ADC8773C-1B27-48ac-BAC1-14C1C919FAF6" => ["wtr::WaterBody", "wtr::WaterSurface"],
      "9994BF62-51E2-42cd-BB35-16C537B6718A" => ["urf::TreePlantingDistrict"]
    }.each do |diagram_id, expected|
      expect(compartment_texts(document, diagram_id).map(&:text)).to include(*expected)
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Element::HeaderLines do
  it "preserves fitting qualifiers, colon-bearing names, and ordinary word wrapping" do
    [
      ["string", "xs", 100, ["xs::string"]],
      ["xs:string", nil, 100, ["xs:string"]],
      ["xs:nonNegativeInteger", nil, 101, ["xs:", "nonNegativeInteger"]],
      ["Section: Heading", nil, 1, ["Section:", "Heading"]],
      ["Plain", nil, 100, ["Plain"]],
      ["Two Words", nil, 1, %w[Two Words]]
    ].each do |name, package, width, expected|
      classifier = Ea::Model::Klass.new(name: name)
      lines = described_class.for(classifier, foreign_package_name: package,
                                              bounds_width: width, font_size: 7, family: "Cambria")

      expect(lines).to eq(expected.map { |line| [line, :bold] })
    end
  end
end
