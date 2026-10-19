# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI connector bend point sign" do
  include QeaBridgeCorpusHelpers
  include XmiBendSignHelpers

  describe "Path parsing" do
    it "negates EA's stored Y into screen-positive Y" do
      expect(parsed_bends("338:-407$273:-643$")).to eq([[338, 407], [273, 643]])
    end

    it "flips a positive stored Y the same way" do
      expect(parsed_bends("10:5$")).to eq([[10, -5]])
    end

    it "returns no bends for an empty Path" do
      expect(parsed_bends("")).to eq([])
    end
  end

  context "with the plateau corpus" do
    before do
      skip "plateau XMI unavailable" unless File.exist?(plateau_xmi_path)
      skip "plateau QEA unavailable" unless File.exist?(plateau_path)
    end

    {
      "d147 connector 481" => ["{E7AABA98-2450-4986-9736-DCCAF0108C50}",
                               "{852FF005-A86B-4c4e-B0FB-C08CBDA4CC5A}", [[338, 407]]],
      "d148 connector 724" => ["{00C5C772-5A03-434f-BF30-AC37542A1AAC}",
                               "{86668E1A-8EB0-4b0a-8B88-B0AEDA505BD6}", [[273, 342], [273, 643]]]
    }.each do |name, (diagram, connector, interior)|
      it "keeps #{name} bends positive and equal to the QEA bends" do
        xmi = xmi_connector_points(diagram, connector)

        expect(xmi[1...-1]).to eq(interior)
        expect(xmi[1...-1]).to eq(qea_connector_points(diagram, connector)[1...-1])
      end
    end

    it "puts a bent connector's bends on the native SVG vertices" do
      diagram = "{13E09C71-99E7-40b4-B72D-48AF6379BC2E}"
      points = xmi_connector_points(diagram, "{A6B31A84-81F1-491b-930F-2019375C00B1}")
      dx, dy = native_shift(diagram, "6F915D44_6B5C_4298_891D_0FB0B1AF24F0")

      expect(native_shift(diagram, "E66C1C01_AE82_4fc8_ACB5_0C3541A6240A")).to eq([dx, dy])
      expect(points[1...-1].map { |x, y| [x + dx, y + dy] }).to eq([[241, 321], [463, 321]])
    end

    it "leaves a bendless connector unchanged" do
      expect(xmi_connector_points("{73025C5A-08FC-47ff-AB2F-C7F79CF54B41}", "{E7FFECEB-996C-45b0-8E47-A56B4834C7DF}"))
        .to eq([[620, 584], [620, 701]])
    end
  end
end
