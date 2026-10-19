# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA association-class tether" do
  include QeaAssociationClassHelpers

  it "connects the saved proxy anchor to the placed class with a dashed line" do
    xml = render_association_class

    expect(xml.css("path").map { |node| node["d"] }).to eq(["M 522 644 L 657 645"])
    expect(xml.at_css("path").parent["style"]).to include("stroke-dasharray:6,3")
  end

  it "docks the class on the side facing the saved anchor" do
    [
      [[217, 601, 170, 88], "M 522 644 L 387 645"],
      [[437, 400, 170, 88], "M 522 644 L 522 488"],
      [[437, 800, 170, 88], "M 522 644 L 522 800"]
    ].each do |bounds, expected|
      xml = render_association_class(class_bounds: bounds)

      expect(xml.css("path").map { |node| node["d"] }).to eq([expected])
    end
  end

  it "preserves ordinary or unresolved proxy associations" do
    [{ subtype: nil }, { class_id: "missing" }, { class_id: "999" }, { placed: false },
     { proxy_type: "Class" }, { classifier: nil }, { second_classifier: "other" }].each do |attributes|
      xml = render_association_class(**attributes)

      expect(xml.css("path").map { |node| node["d"] }).to eq(["M 522 644 L 522 644"]), attributes.inspect
      expect(xml.at_css("path").parent["style"]).not_to include("stroke-dasharray"), attributes.inspect
    end
  end
end
