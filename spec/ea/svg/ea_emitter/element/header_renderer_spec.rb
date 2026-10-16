# frozen_string_literal: true

require "spec_helper"
require "ea"
require "nokogiri"

RSpec.shared_context "classifier header rendering" do
  let(:bounds) { Ea::Model::Bounds.new(x: 140, y: 33, width: 212, height: 125) }
  let(:lines) do
    [["_TransportationObject", :italic], ["«FeatureType»", :normal],
     ["tran::TransportationComplex", :bold]]
  end
  let(:svg) do
    described_class.render(lines, bounds: bounds, first_y: 48,
                                  family: "Carlito", size: 9)
  end
  let(:texts) { Nokogiri::XML(svg).remove_namespaces!.xpath("//text") }
end

RSpec.describe Ea::Svg::EaEmitter::Element::HeaderRenderer do
  include_context "classifier header rendering"

  it "insets the parent ghost while preserving the centered stereotype and name" do
    # EA-published 0016F797: the ghost ends 3px inside the box.
    expect(texts.map { |text| [text["x"], text["y"], text["textLength"]] })
      .to eq([["230.00", "48.00", "119"], ["206.00", "69.00", "79"],
              ["166.00", "84.00", "160"]])
  end

  context "with a tight interface parent ghost" do
    let(:lines) do
      [["_TransportationObject", :italic_tight], ["«interface»", :normal],
       ["Surface", :bold]]
    end

    it "keeps the parent italic and inset with the tighter following-line pitch" do
      expect([texts.first["x"], texts.first["y"], texts.first["textLength"]])
        .to eq(["230.00", "48.00", "119"])
      expect(texts.first["style"]).to include("font-style:italic")
      expect(texts.map { |text| text["y"] }).to eq(["48.00", "66.00", "81.00"])
    end
  end

  context "with an abstract name and no parent ghost" do
    let(:lines) { [["_TransportationObject", :bold_italic]] }

    it "keeps the abstract name centered and italic" do
      expect(texts.first["x"]).to eq("184.00")
      expect(texts.first["style"]).to include("font-weight:700; font-style:italic")
    end
  end
end
