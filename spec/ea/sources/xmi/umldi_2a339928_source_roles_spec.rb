# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "2A339928 independent source role ownership" do
  include Umldi2a339928Helpers

  Umldi2a339928Helpers::CASES.each do |name, data|
    it "retains the joined #{name} source bounds alongside authored extension geometry" do
      xml = held_out_xml
      connector = held_out_connector(xml, data[:association])
      expect(connector.umldi_label_bounds).to eq(source_role: data[:bounds])
      expect(connector.label_boxes).to include(
        llt: include("ox" => 0, "oy" => 0, "cx" => data[:llt_width], "cy" => 35),
        llb: include("ox" => 0, "oy" => 0, "cx" => 21, "cy" => 18)
      )
      expect(connector.umldi_label_bounds).not_to have_key(:source_multiplicity)
      expect(connector.waypoints.map { |point| [point.position.x, point.position.y] }).to eq(data[:route])
      expect([connector.source_port, connector.target_port].map { |point| [point.x, point.y] })
        .to eq(data[:ports])
    end
  end
end

RSpec.describe "2A339928 source identity guards" do
  include Umldi2a339928Helpers

  Umldi2a339928Helpers::CASES.each do |name, data|
    Umldi2a339928Helpers::IDENTITY_CHANGES.each do |guard, change|
      it "keeps #{name} LLT precedence with #{guard}" do
        xml = held_out_xml
        change.call(xml, data)
        connector = held_out_connector(xml, data[:association])
        expect(connector.umldi_label_bounds).to eq({})
        expect(connector.label_boxes.fetch(:llt)).to include("cx" => data[:llt_width], "cy" => 35)
        expect(connector.waypoints.map { |point| [point.position.x, point.position.y] }).to eq(data[:route])
      end
    end
  end
end
