# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "QEA package tab baselines" do
  include QeaCompartmentFontHelpers

  let(:document) { public_compartment_document }

  it "seats larger package names and compact Cambria names at published coordinates" do
    [
      ["37AC19B9-8433-4fee-A326-763170D54D06",
       { "都市計画基本図" => [15, 25], "都市計画決定情報モデル" => [405, 25],
         "都市計画基礎調査" => [195, 25] }],
      ["D4DA8C48-3998-450d-87C4-9D65C9FECDB4",
       { "urf" => [188, 35], "uro" => [15, 35], "urt" => [534, 35], "urg" => [361, 35] }],
      ["DFBB1072-8EC5-4384-8241-7EDF4B6B888B",
       { "3D都市モデル" => [160, 40], "i-UR" => [305, 200],
         "CityGML2.0" => [15, 210], "gml" => [177, 376] }]
    ].each do |id, expected|
      diagram = document.diagrams.find { |entry| entry.id == id }
      svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                      document: document).render
      texts = Nokogiri::XML(svg).remove_namespaces!.css("text")
      expected.each do |text, position|
        rows = texts.select { |node| node.text == text }

        expect(rows.length).to eq(1)
        expect([rows.first["x"].to_f - 25, rows.first["y"].to_f - 30])
          .to eq(position)
      end
    end
  end
end
