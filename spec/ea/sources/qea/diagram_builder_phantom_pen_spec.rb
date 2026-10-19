# frozen_string_literal: true

require "spec_helper"

RSpec.shared_context "a QEA connector pen" do
  include QeaEndLabelHelpers

  let(:tables) do
    qea_end_label_tables("", {}, [141, 689, 100, 80], [153, 240, 387, 173], { mult: "0..1" })
  end
  let(:database) { build_test_database(**tables) }
  let(:document) { Ea::Sources::Qea::Adapter.new(database, "phantom-pen.qea").to_document }
  let(:diagram) { document.diagrams.first }
  let(:connector) { diagram.connectors.first }
  let(:xml) do
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                    document: document, frame: false).render
    Nokogiri::XML(svg).remove_namespaces!
  end
end

RSpec.describe "QEA phantom connector pens" do
  include_context "a QEA connector pen"

  %w[Association Aggregation Dependency Generalization].each do |type|
    context "with an inferred #{type}" do
      before do
        tables[:diagram_links] = []
        tables[:connectors].first.connector_type = type
      end

      it "uses a one-pixel source pen while preserving the theme default" do
        expect(connector.style[:lwidth]).to eq("1")
        expect(xml.at_css("path").parent["style"]).to include("stroke-width:1;")
        expect(diagram.theme.connector_line_width).to eq(2)
      end
    end
  end
end

RSpec.describe "QEA saved connector pens" do
  include_context "a QEA connector pen"

  [["Mode=1;", nil, 2], ["Mode=1;LWidth=2;", "2", 2],
   ["Mode=1;LWidth=4;", "4", 4]].each do |style, source_width, width|
    context "with saved link style #{style}" do
      before { tables[:diagram_links].first.style = style }

      it "preserves the saved pen and theme fallback" do
        expect(connector.style[:lwidth]).to eq(source_width)
        expect(xml.at_css("path").parent["style"]).to include("stroke-width:#{width};")
        expect(diagram.theme.connector_line_width).to eq(2)
      end
    end
  end
end
