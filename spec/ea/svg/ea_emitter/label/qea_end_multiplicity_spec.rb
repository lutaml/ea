# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA target multiplicity with stored offsets" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers

  it "seats an upward target at its stored corner, as plateau diagram 82 does" do
    result = render_qea_end_labels(path: "200:-200;200:-300;",
                                   boxes: { "LRT" => [63, -31], "LRB" => [4, -28] },
                                   source: [100, 100, 200, 100], target: [100, 300, 200, 100],
                                   mult: "1", end: :target)

    expect(result[:mult]).to eq([result[:last][0] + 12, result[:last][1] - 35])
  end

  it "keeps plain upward target labels at their stored offsets" do
    result = render_qea_end_labels(path: "200:-200;200:-300;",
                                   boxes: { "LRT" => [63, -31], "LRB" => [4, -28] },
                                   source: [100, 100, 200, 100], target: [100, 300, 200, 100],
                                   mult: "1", end: :target, stereotype: nil)

    expect(result[:mult]).to eq([result[:last][0] + 4, result[:last][1] + 28])
  end

  it "keeps a downward target's stored offsets" do
    result = render_qea_end_labels(path: "200:-300;200:-200;",
                                   boxes: { "LRT" => [63, -31], "LRB" => [4, -28] },
                                   source: [100, 300, 200, 100], target: [100, 100, 200, 100],
                                   mult: "1", end: :target)

    expect(result[:mult]).to eq([result[:last][0] + 4, result[:last][1] + 28])
  end
end
