# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require "ea/transformers/qea_to_xmi"

# Issue #32 parity ratchet: ID-set distance between our exports and
# EA's own reference exports, for EVERY model with a checked-in
# reference. The pre-fix baseline on basic was 421 only-in-ours /
# 368 only-in-EA / 237 mismatched. These ceilings hold the current
# distance — they may only go DOWN as later work closes the remaining
# gaps (deep-nested LI ordering, EAJava primitive hierarchy, package
# imports, MDG content, true EA round-trip).
RSpec.describe "QEA to XMI parity ratchet" do
  RATCHET = {
    "basic" => { only_ours: 147, only_ea: 148, mismatched: 100 },
    "simple" => { only_ours: 1, only_ea: 75, mismatched: 0 },
    "test" => { only_ours: 17, only_ea: 305, mismatched: 3 },
    "ArcGISWorkspace_template" => { only_ours: 1, only_ea: 463, mismatched: 2 },
    "UmlModel_template" => { only_ours: 0, only_ea: 1, mismatched: 0 },
  }.freeze

  XMI_NS = { "xmi" => "http://www.omg.org/spec/XMI/20110701" }.freeze

  def id_map(xml)
    map = {}
    Nokogiri::XML(xml).xpath("//*[@xmi:id]", XMI_NS).each do |element|
      map[element["xmi:id"]] = [element.name, element.attributes.transform_values(&:value)]
    end
    map
  end

  RATCHET.each do |model, ceiling|
    context model do
      it "keeps ID and attribute parity within the ratchet" do
        database = Ea::Qea.load("examples/qea/#{model}.qea")
        begin
          ours = id_map(Ea::Transformers.qea_to_xmi(database))
          ref = id_map(File.read("examples/exports/#{model}/model.xml"))
          common = ours.keys & ref.keys
          mismatched = common.count { |id| ours[id] != ref[id] }
          expect((ours.keys - ref.keys).size).to be <= ceiling[:only_ours]
          expect((ref.keys - ours.keys).size).to be <= ceiling[:only_ea]
          expect(mismatched).to be <= ceiling[:mismatched]
        ensure
          database.close_connection
        end
      end
    end
  end

  it "self-parses through the Sparx XMI model" do
    database = Ea::Qea.load("examples/qea/basic.qea")
    begin
      output = Ea::Transformers.qea_to_xmi(database)
      expect { ::Xmi::Sparx::Root.parse_xml(output) }.not_to raise_error
    ensure
      database.close_connection
    end
  end
end
