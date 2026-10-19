# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Operation signature insets" do
  include OperationInsetHelpers

  it "uses the compact Cambria seven point cell for signatures while preserving visibility and parameters" do
    { "public" => "+ ", "private" => "- ", "protected" => "# ", "package" => "~ " }.each do |visibility, marker|
      nodes = operation_inset_nodes(family: "Cambria", size: 7, visibility: visibility)

      expect(nodes.map(&:text)).to eq([marker, "resize(width: int): void"])
      expect(nodes.map { |node| node["x"].to_f }).to eq([15, 31])
      expect(nodes.map { |node| node["y"].to_f }).to eq([50, 50])
      expect(nodes.map { |node| node["style"] }).to all(include("font-family:Cambria;", "font-size:7pt;"))
    end
  end

  it "preserves noncompact font and size insets" do
    [["Cambria", 8, "pt", 34], ["Cambria", 9, "pt", 36],
     ["Cambria", 7, "px", 32], ["Carlito", 7, "pt", 32],
     ["Carlito", 9, "pt", 36], ["Arial", 7, "pt", 32]].each do |family, size, unit, content_x|
      nodes = operation_inset_nodes(family: family, size: size, unit: unit)

      expect(nodes.map { |node| node["x"].to_f }).to eq([15, content_x])
      expect(nodes.map(&:text)).to eq(["+ ", "resize(width: int): void"])
      expect(nodes.map { |node| node["style"] }).to all(include("font-family:#{family};", "font-size:#{size}#{unit};"))
    end
  end
end

RSpec.describe "QEA operation signature insets" do
  include QeaContentHelpers

  it "matches native basic diagrams 15 and 18 operation marker gaps with their default font" do
    document = Ea::Sources::Qea::Adapter.from_path("examples/qea/basic.qea")
    %w[2AAB709F D2FA55D3].each do |guid|
      texts = qea_text_nodes(document, guid)
      signatures = texts.select { |node| node.text.start_with?("Operation ") }

      expect(signatures.size).to eq(6)
      signatures.each do |signature|
        marker = signature.previous_element
        expect(marker.text).to eq("+ ")
        expect(signature["x"].to_f - marker["x"].to_f).to eq(16)
        expect(signature["style"]).to include("font-family:Cambria;", "font-size:7pt;")
      end
      expect(signatures.map(&:text)).to include("Operation A(int): void", "Operation B(int): void")
    end
  end
end
