# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI connector label boxes" do
  include XmiLabelBoxHelpers

  let(:connectors) { basic_label_box_connectors("Starter Object Diagram", "1137B03A-C00A-443b-A3A8-D5CF6A7AFF13") }

  it "carries every saved label attribute under the QEA key names" do
    expect(connectors.first.label_boxes).to eq(
      lmt: { "ox" => 0, "oy" => 0, "cx" => 27, "cy" => 13, "hidden" => false, "bold" => false,
             "italic" => false, "underline" => false, "color" => -1, "alignment" => 1,
             "direction" => 0, "rotation" => 0 }
    )
  end

  it "matches the label boxes the QEA source saves for the same connector" do
    xmi, qea = connectors
    expect(xmi.label_boxes).to eq(qea.label_boxes)
  end
end
