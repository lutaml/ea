# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Xmi::Adapter do # rubocop:disable Metrics/BlockLength
  include XmiConnectorProxyHelpers

  subject(:document) { connector_proxy_document }

  it "preserves proxy identity, package membership, and reference lookup" do
    expect(document.classifiers.map(&:id)).to eq(%w[proxy real])
    expect(document.packages.first.classifier_ids).to eq(%w[proxy real])
    expect(document.index_by_id["proxy"].name).to eq("ProxyConnector")
  end

  it "preserves a genuine class named ProxyConnector and its properties" do
    classifier = document.classifiers.find { |item| item.id == "real" }
    expect(classifier.name).to eq("ProxyConnector")
    expect(classifier.properties.map(&:id)).to eq(["attribute"])
    expect(document.property_by_id("attribute").name).to eq("value")
  end

  it "preserves connector identity and proxy endpoint references" do
    association = document.relationships.first
    expect(association.id).to eq("association")
    expect([association.source_id, association.target_id]).to eq(%w[proxy real])
  end

  it "keeps an ordinary same-named UML class without EA extension metadata" do
    expect(connector_proxy_document(extension: false).classifiers.map(&:id)).to eq(%w[proxy real])
  end

  it "does not emit an EA connector proxy as a class title" do
    svg = Nokogiri::XML(connector_proxy_svg(document))
    expect(svg.xpath("//*[local-name()='text']").map(&:text).count("ProxyConnector")).to eq(1)
    expect(svg.xpath("//*[local-name()='rect'][@x='10']")).to be_empty
  end
  it "preserves proxy placement and recorded connector bounds" do
    placement = document.diagrams.first.elements.first
    expect(placement.model_element_ref).to eq("proxy")
    expect(placement.bounds.x).to eq(10)
    elements = Ea::Svg::EaEmitter::Elements.new(document.diagrams.first,
                                                model_index: document.index_by_id,
                                                document: document)
    elements.render
    expect(elements.drawn_bounds.fetch("proxy").width).to eq(100)
  end

  it "preserves the graphical proxy discriminator through JSON" do
    restored = Ea::Model::Document.from_json(document.to_json)
    expect(restored.diagrams.first.elements.first.style["connector_proxy"]).to be(true)
    expect(restored.index_by_id["proxy"].name).to eq("ProxyConnector")
    expect(connector_proxy_svg(restored)).not_to include('x="10"')
  end
end
