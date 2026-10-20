# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require "xmi"

RSpec.describe "XMI classifier member order" do
  it "renders owned attributes in their saved order" do
    xml = File.read("spec/fixtures/basic.xmi")
    xml = xml.sub('name="attribute One" visibility="private"', 'name="zulu" visibility="private"')
    xml = xml.sub('name="attribute Two" visibility="private"', 'name="alpha" visibility="private"')
    root = Xmi::Sparx::Root.parse_xml(xml)
    document = Ea::Sources::Xmi::Adapter.new(root).to_document
    diagram = document.diagrams.find { |candidate| candidate.id.include?("D351FC34") }
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document
    ).render
    lines = Nokogiri::XML(svg).remove_namespaces!.xpath("//text").map(&:text)

    expect(lines.index { |line| line.include?("zulu") })
      .to be < lines.index { |line| line.include?("alpha") }
  end
end
