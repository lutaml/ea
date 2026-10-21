# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require "xmi"

RSpec.describe "XMI classifier member order" do
  let(:render_fixture) do
    lambda do |xml|
      xml = xml.sub('name="attribute One" visibility="private"', 'name="zulu" visibility="private"')
      xml = xml.sub('name="attribute Two" visibility="private"', 'name="alpha" visibility="private"')
      root = Xmi::Sparx::Root.parse_xml(xml)
      document = Ea::Sources::Xmi::Adapter.new(root).to_document
      diagram = document.diagrams.find { |candidate| candidate.id.include?("D351FC34") }
      svg = Ea::Svg::EaEmitter::Document.new(
        diagram, model_index: document.index_by_id, document: document,
        frame: true
      ).render
      lines = Nokogiri::XML(svg).remove_namespaces!.xpath("//text").map(&:text)
      [document, lines]
    end
  end

  it "renders owned attributes in their saved order" do
    _document, lines = render_fixture.call(File.read("spec/fixtures/basic.xmi"))
    expect(lines.index { |line| line.include?("zulu") })
      .to be < lines.index { |line| line.include?("alpha") }
  end
end

RSpec.describe "XMI DataType member order" do
  it "preserves saved attribute order for DataType classifiers" do
    xml = File.read("spec/fixtures/basic.xmi").sub(
      'xmi:type="uml:Class" xmi:id="EAID_4DEF666F_E8F2_4ace_B9AC_E15A5ACDCADD"',
      'xmi:type="uml:DataType" xmi:id="EAID_4DEF666F_E8F2_4ace_B9AC_E15A5ACDCADD"'
    )
    xml = xml.sub('name="attribute One" visibility="private"', 'name="zulu" visibility="private"')
    xml = xml.sub('name="attribute Two" visibility="private"', 'name="alpha" visibility="private"')
    root = Xmi::Sparx::Root.parse_xml(xml)
    document = Ea::Sources::Xmi::Adapter.new(root).to_document
    diagram = document.diagrams.find { |candidate| candidate.id.include?("D351FC34") }
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document,
      frame: true
    ).render
    lines = Nokogiri::XML(svg).remove_namespaces!.xpath("//text").map(&:text)

    expect(document.index_by_id.fetch("EAID_4DEF666F_E8F2_4ace_B9AC_E15A5ACDCADD"))
      .to be_a(Ea::Model::DataType)
    expect(lines.index { |line| line.include?("zulu") })
      .to be < lines.index { |line| line.include?("alpha") }
  end
end
