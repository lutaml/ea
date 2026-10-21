# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA diagonal target Property seats through the public adapter" do
  let(:document) do
    Ea::Sources::Qea::Adapter.from_path("examples/qea/20251010_current_plateau_v5.1.qea")
  end

  it "matches the native role and stereotype seats on the leftward and upward diagonal targets" do
    [["88D0CB44-20D0-44fc-A6E3-B663332EF401", [519, 505]],
     ["A081C63E-D6F2-41a7-A99C-307836754AFA", [590, 633]]].each do |id, expected|
      diagram = document.diagrams.find { |candidate| candidate.id == id }
      svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                      document: document, frame: true).render
      texts = Nokogiri::XML(svg).remove_namespaces!.css("text")
      role = texts.find { |text| text.text == "+referencePoint" }
      stereotype = role.next_element

      expect([role["x"].to_f, role["y"].to_f]).to eq(expected)
      expect(stereotype.text).to eq("«property»")
      expect([stereotype["x"].to_f, stereotype["y"].to_f]).to eq([expected[0] + 11, expected[1] + 12])
    end
  end
end
