# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Operation parameter detail (diagram OpParams)" do
  include QeaContentHelpers

  let(:document) { Ea::Sources::Qea::Adapter.from_path("examples/qea/basic.qea") }
  let(:renderer) { Ea::Svg::EaEmitter::Element::OperationRenderer }

  def operation(*params)
    op = Ea::Model::Operation.new(name: "Op", visibility: "public")
    op.parameters = params
    op.return_type_name = "void"
    op
  end

  def parameter(direction: "in")
    Ea::Model::Parameter.new(name: "Parameter A", type_name: "int", direction: direction)
  end

  def detail_for(style)
    Ea::Diagram::DisplayConfig.from_style(style: style, style_ex: nil).operation_parameter_detail
  end

  it "draws type-only signatures on OpParams=1 diagrams" do
    texts = qea_texts(document, "2AAB709F") + qea_texts(document, "D2FA55D3")

    expect(texts).to include("Operation A(int): void", "Operation B(int): void")
    expect(texts.grep(/Parameter/)).to be_empty
  end

  it "maps OpParams=1 to :type_only and leaves other values unspecified" do
    expect(detail_for("OpParams=1;")).to eq(:type_only)
    expect(detail_for("OpParams=0;")).to be_nil
    expect(detail_for("OpParams=2;")).to be_nil
    expect(detail_for(nil)).to be_nil
  end

  it "keeps named signatures when no detail is specified" do
    classifier = Struct.new(:operations).new([operation(parameter)])

    expect(renderer.operation_text(operation(parameter))).to eq("Op(Parameter A: int): void")
    expect(renderer.lines_for(classifier)).to eq(["+ Op(Parameter A: int): void"])
  end

  it "keeps the inout star form in type-only mode" do
    op = operation(parameter, parameter(direction: "inout"))

    expect(renderer.operation_text(op, parameter_detail: :type_only)).to eq("Op(int, int*): void")
    expect(renderer.operation_text(op)).to eq("Op(Parameter A: int, int*): void")
  end

  it "applies type-only to display lines and receptions" do
    classifier = Struct.new(:operations).new([operation(parameter)])
    reception = operation(parameter)
    reception.is_reception = true

    expect(renderer.lines_for(classifier, parameter_detail: :type_only)).to eq(["+ Op(int): void"])
    expect(renderer.operation_text(reception, parameter_detail: :type_only)).to eq("«signal» Op(int)")
  end
end
