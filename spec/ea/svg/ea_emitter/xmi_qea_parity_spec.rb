# frozen_string_literal: true

require "spec_helper"

# XMI renders must equal the QEA render of the same model where native EA
# agrees: object-diagram chrome, package nesting/dependency docks, association
# end labels, class constraints and the default signal header.
RSpec.describe "XMI and QEA agree on the same model" do
  fixtures = File.expand_path("../../../fixtures", __dir__)
  examples = File.expand_path("../../../../examples/qea", __dir__)

  def render(document, fragment)
    diagram = document.diagrams.find { |d| d.id.to_s.upcase.tr("_", "-").include?(fragment) }
    Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document).render
  end

  def shapes(svg)
    svg.scan(/<(?:path|ellipse|rect)\b[^>]*>/).map do |tag|
      tag[/\b(?:d|cx|x)="[^"]*"/].to_s + tag[/\b(?:cy|y)="[^"]*"/].to_s
    end
  end

  def texts(svg)
    svg.scan(/<text\b([^>]*)>([^<]*)/).map do |attrs, body|
      [attrs[/\bx="([\d.]+)"/, 1].to_f, attrs[/\by="([\d.]+)"/, 1].to_f, body]
    end
  end

  let(:basic_xmi) { Ea::Sources::Xmi::Adapter.from_path(File.join(fixtures, "basic.xmi")) }
  let(:basic_qea) { Ea::Sources::Qea::Adapter.from_path(File.join(examples, "basic.qea")) }

  describe "Ea::Model::Diagram#object_diagram?" do
    it "ignores the case QEA (Object) and XMI (object) spell it in" do
      expect(%w[Object object OBJECT].map { |t| Ea::Model::Diagram.new(diagram_type: t).object_diagram? })
        .to eq([true, true, true])
      expect(%w[Class Logical].map { |t| Ea::Model::Diagram.new(diagram_type: t).object_diagram? })
        .to eq([false, false])
    end
  end

  it "draws the object-diagram instance underline and header divider in XMI" do
    xmi = shapes(render(basic_xmi, "14E9F5FD"))
    qea = shapes(render(basic_qea, "14E9F5FD"))

    expect(xmi.sort).to eq(qea.sort)
  end

  it "docks package nesting connectors on the container edge, not its top" do
    xmi = shapes(render(basic_xmi, "F0F20BDF"))

    expect(xmi.sort).to eq(shapes(render(basic_qea, "F0F20BDF")).sort)
    expect(xmi).to include('d="M 281 90 L 281 106 M 289 98 L 273 98"')
  end

  it "docks package dependencies on the package edges" do
    xmi = shapes(render(basic_xmi, "0EDEA6EF"))

    expect(xmi).to include('d="M 140 106 L 200 106 L 200 168 L 250 168"')
    expect(xmi.sort).to eq(shapes(render(basic_qea, "0EDEA6EF")).sort)
  end

  describe "test.xmi association B58D1A53" do
    let(:xmi) { Ea::Sources::Xmi::Adapter.from_path(File.join(fixtures, "test.xmi")) }
    let(:svg) { render(xmi, "B58D1A53") }

    it "labels each end with its own role, without the opposite end's typed property" do
      roles = texts(svg).select { |_, _, body| body.start_with?("+role") }

      expect(roles.sort_by(&:first).map(&:last)).to eq(%w[+role1 +role2])
    end

    it "seats the multiplicities at their own ends" do
      mult = texts(svg).to_h { |x, _, body| [body, x] }

      expect(mult.fetch("0..*")).to be < mult.fetch("1")
    end

    it "draws the DataType2 constraint compartment" do
      body = texts(svg).map(&:last)

      expect(body).to include("constraints", "{pattern}")
    end
  end

  it "seats the default signal header like QEA and native EA" do
    xmi = Ea::Sources::Xmi::Adapter.from_path(File.join(fixtures, "simple.xmi"))
    header = texts(render(xmi, "204F4ACC")).select { |_, _, body| %w[«signal» AcmeUmlSignal].include?(body) }

    expect(header.map { |_, y, body| [body, y] }).to eq([["«signal»", 72.0], ["AcmeUmlSignal", 87.0]])
  end
end
