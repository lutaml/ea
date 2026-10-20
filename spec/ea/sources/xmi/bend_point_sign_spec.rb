# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI connector bend point sign" do
  include QeaBridgeCorpusHelpers
  include XmiBendSignHelpers
  include XmiStoredRouteHelpers

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

  describe Ea::Sources::Xmi::StoredRoute do
    it "declines a connector with neither bends nor ports, leaving it to the generic router" do
      expect(stored_route_for("Mode=2;LWidth=1;", "Association")).to be_nil
    end

    it "declines a width-2 Mode 3 connector with neither bends nor ports" do
      expect(stored_route_for("Mode=3;LWidth=2;", "Aggregation")).to be_nil
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

    {
      "d147 connector 481 (stored square)" => ["{E7AABA98-2450-4986-9736-DCCAF0108C50}",
                                               "{852FF005-A86B-4c4e-B0FB-C08CBDA4CC5A}"],
      "d148 connector 724 (stored stair)" => ["{00C5C772-5A03-434f-BF30-AC37542A1AAC}",
                                              "{86668E1A-8EB0-4b0a-8B88-B0AEDA505BD6}"],
      "d147 connector 653 (Generalization, missing EX/EY)" => ["{E7AABA98-2450-4986-9736-DCCAF0108C50}",
                                                               "{EA1781F9-1F59-41f2-9650-C491DE7B69B9}"],
      "d148 connector 672 (Generalization, zero SX/SY/EX)" => ["{00C5C772-5A03-434f-BF30-AC37542A1AAC}",
                                                               "{5BEB3B26-2EE2-4cd8-B09B-C8917830092A}"],
      "d148 1725DF12 (facing-edge Association)" => ["{00C5C772-5A03-434f-BF30-AC37542A1AAC}",
                                                    "{1725DF12-B511-4d41-AA74-59C65BDF5C48}"],
      "d148 9FE940C6 (Mode 1 drops the Path)" => ["{00C5C772-5A03-434f-BF30-AC37542A1AAC}",
                                                  "{9FE940C6-5F42-4194-9296-BFCCE85A6460}"],
      "d147 connector 848 (level entry)" => ["{E7AABA98-2450-4986-9736-DCCAF0108C50}",
                                             "{AD628304-78EA-4E0B-B4AF-39769E39D20E}"]
    }.each do |name, (diagram, connector)|
      it "docks #{name} exactly where QEA does" do
        expect(xmi_connector_points(diagram, connector)).to eq(qea_connector_points(diagram, connector))
      end
    end

    it "puts a bent connector's bends on the native SVG vertices" do
      diagram = "{13E09C71-99E7-40b4-B72D-48AF6379BC2E}"
      points = xmi_connector_points(diagram, "{A6B31A84-81F1-491b-930F-2019375C00B1}")
      dx, dy = native_shift(diagram, "6F915D44_6B5C_4298_891D_0FB0B1AF24F0")

      expect(native_shift(diagram, "E66C1C01_AE82_4fc8_ACB5_0C3541A6240A")).to eq([dx, dy])
      expect(points[1...-1].map { |x, y| [x + dx, y + dy] }).to eq([[241, 321], [463, 321]])
    end

    it "docks a zero-offset bent Association where QEA and the native SVG do" do
      expect(xmi_connector_points("{13E09C71-99E7-40b4-B72D-48AF6379BC2E}", "{A6B31A84-81F1-491b-930F-2019375C00B1}"))
        .to eq([[326, 629], [326, 531], [548, 531], [548, 482]])
    end

    it "leaves a connector without stored geometry on the generic router" do
      expect(xmi_connector_points("{4881CEEE-792C-4cb0-BEA7-54333B643D0A}", "{351EC738-E01B-45ff-B3E0-395258918C14}"))
        .to eq([[378, 84], [324, 84]])
    end
  end
end
