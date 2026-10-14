# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Label::MidpointLabel do
  let(:dependency) do
    Ea::Model::Dependency.new(id: "dep1", client_id: "c1",
                              supplier_id: "c2", stereotype: "import")
  end
  let(:association) do
    Ea::Model::Association.new(id: "assoc1", source_id: "c1", target_id: "c2")
  end
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [
        Ea::Model::Klass.new(id: "c1", name: "A"),
        Ea::Model::Klass.new(id: "c2", name: "B")
      ],
      relationships: [dependency, association]
    )
  end
  let(:model_index) { document.index_by_id }
  let(:label_size) { 7 }

  def renderer
    described_class.new(canvas: nil, model_index: model_index,
                        font_family: "Carlito", font_size: label_size, font_unit: "pt")
  end

  def connector_for(relationship)
    Ea::Model::DiagramConnector.new(
      id: "dc_#{relationship.id}",
      relationship_ref: relationship.id,
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ]
    )
  end

  it "returns «stereotype» for a connector with an applied stereotype" do
    expect(renderer.stereotype_label(connector_for(dependency)))
      .to eq("«import»")
  end

  it "renders the stereotype text at the connector midpoint" do
    out = renderer.text_for(connector_for(dependency),
                            [[0, 0], [100, 0]])
    expect(out).to include("«import»")
    expect(out).to include('x="50') # midpoint of [0,0]–[100,0]
  end

  it "returns nil for a relationship without stereotype" do
    bare_dep = Ea::Model::Dependency.new(id: "dep2", client_id: "c1",
                                         supplier_id: "c2")
    doc = Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [
        Ea::Model::Klass.new(id: "c1", name: "A"),
        Ea::Model::Klass.new(id: "c2", name: "B")
      ],
      relationships: [bare_dep]
    )
    r = described_class.new(canvas: nil, model_index: doc.index_by_id,
                            font_family: "Carlito", font_size: 7, font_unit: "pt")
    expect(r.stereotype_label(connector_for(bare_dep))).to be_nil
  end

  it "returns nil for an association (handled by EndLabel)" do
    expect(renderer.stereotype_label(connector_for(association))).to be_nil
  end
  context "with a stored substitutability label seat" do # rubocop:disable Metrics/BlockLength
    let(:generalization) do
      Ea::Model::Generalization.new(id: "gen1", specific_id: "c1", general_id: "c2",
                                    name: "{isSubstitutable=false}")
    end
    let(:model_index) { { generalization.id => generalization } }
    let(:connector_attributes) do
      {
        id: "seat", relationship_ref: generalization.id,
        connector_type: "Generalization", is_substitutable: true,
        label_boxes: { lmb: { "ox" => 0, "oy" => 0, "hidden" => false,
                              "rotation" => 0, "alignment" => 0 } }
      }
    end

    it "seats the annotation beside the first vertical segment and preserves other seats" do # rubocop:disable Metrics/BlockLength
      points = [[666, 640], [666, 525], [329, 525], [329, 475]]
      box = connector_attributes[:label_boxes][:lmb]
      cases = [
        [points, {}, [669, 581]],
        [[[205, 1070], [205, 1031], [347, 1031], [347, 981]], {}, [208, 1049]],
        [points, { label_boxes: {} }, [497, 525]],
        [points, { is_substitutable: false }, [497, 525]],
        [points, { label_boxes: { lmb: { "ox" => 0, "oy" => 0, "hidden" => true,
                                         "rotation" => 0, "alignment" => 0 } } }, [497, 525]],
        [points, { label_boxes: { lmb: { "ox" => 0, "oy" => 0, "hidden" => false,
                                         "rotation" => 30, "alignment" => 0 } } }, [497, 525]],
        [points, { label_boxes: { lmb: { "ox" => 0, "oy" => 0, "hidden" => false,
                                         "rotation" => 0, "alignment" => 1 } } }, [497, 525]],
        [points, { label_boxes: { lmb: box.merge("ox" => 4) } }, [497, 525]],
        [points, { label_boxes: { lmb: box.merge("oy" => 4) } }, [497, 525]],
        [points, { connector_type: "Association" }, [497, 525]],
        [[[0, 100], [40, 100]], {}, [20, 100]],
        [[[0, 100], [0, 50], [40, 0]], {}, [0, 50]],
        [[[0, 100], [0, 50], [20, 50], [20, 25], [40, 25], [40, 0]], {}, [20, 37]],
        [[[0, 0], [0, 50], [40, 50], [40, 100]], {}, [20, 50]],
        [[[0, 100], [20, 50], [40, 50], [40, 0]], {}, [30, 50]],
        [[[0, 50], [0, 50], [40, 50], [40, 0]], {}, [20, 50]]
      ]

      cases.each do |route, attributes, expected|
        connector = Ea::Model::DiagramConnector.new(**connector_attributes.merge(attributes))
        xml = Nokogiri::XML(renderer.text_for(connector, route))
        text = xml.at_xpath('//*[local-name()="text"]')

        expect([text["x"].to_f, text["y"].to_f]).to eq(expected),
                                                    "route: #{route}, attributes: #{attributes}"
        expect(text.text).to eq("{isSubstitutable=false}")
      end
    end

    it "preserves the public seat for non-model connectors" do
      connector = Struct.new(:relationship_ref, :is_substitutable, :connector_type,
                             :label_boxes, keyword_init: true).new(
                               **connector_attributes.reject { |key, _| key == :id }
                             )
      text = Nokogiri::XML(renderer.text_for(connector, [[0, 100], [0, 50], [40, 50], [40, 0]]))
                     .at_xpath('//*[local-name()="text"]')

      expect([text["x"].to_f, text["y"].to_f]).to eq([20, 50])
    end

    context "with an unverified font size" do
      let(:label_size) { 8 }

      it "retains the existing midpoint" do
        connector = Ea::Model::DiagramConnector.new(**connector_attributes)
        text = Nokogiri::XML(renderer.text_for(connector, [[0, 100], [0, 50], [40, 50], [40, 0]]))
                       .at_xpath('//*[local-name()="text"]')

        expect([text["x"].to_f, text["y"].to_f]).to eq([20, 50])
      end
    end

    it "keeps an applied stereotype at the existing midpoint" do
      generalization.stereotype = "import"
      connector = Ea::Model::DiagramConnector.new(**connector_attributes)
      text = Nokogiri::XML(renderer.text_for(connector, [[0, 100], [0, 50], [40, 50], [40, 0]]))
                     .at_xpath('//*[local-name()="text"]')

      expect([text["x"].to_f, text["y"].to_f, text.text]).to eq([20, 50, "«import»"])
    end
  end # rubocop:enable Metrics/BlockLength
end
