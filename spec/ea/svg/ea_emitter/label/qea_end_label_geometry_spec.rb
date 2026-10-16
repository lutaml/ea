# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA end-label geometry through the public adapter" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers

  let(:target_boxes) { qea_zero_boxes("LRT", "LRB") }

  it "seats a source end without stored boxes at its anchor when the other end stores them" do
    result = render_qea_end_labels(path: "200:-300;200:-200;", boxes: target_boxes,
                                   source: [100, 300, 200, 100], target: [100, 100, 200, 100], mult: "0..*")

    expect(result[:mult]).to eq([result[:first][0] + 3, result[:first][1] - 6])
  end

  it "seats a target multiplicity leaving left like a source leaving left" do
    result = render_qea_end_labels(path: "300:-350;500:-350;", boxes: target_boxes, mult: "0..*", end: :target)

    expect(result[:mult]).to eq([result[:last][0] - 17, result[:last][1] + 15])
  end

  it "seats a rightward property multiplicity one text width further out on an H tree route" do
    options = { path: "300:-350;500:-350;", boxes: qea_zero_boxes("LLT", "LLB"), mult: "0..*" }
    tree = render_qea_end_labels(**options, style: "Mode=3;TREE=H;LWidth=2;")
    plain = render_qea_end_labels(**options)

    expect(tree[:mult]).to eq([tree[:first][0] + 3 + 14, tree[:first][1] + 15])
    expect(plain[:mult]).to eq([plain[:first][0] + 3, plain[:first][1] + 15])
  end

  it "keeps the upward target multiplicity seat" do
    result = render_qea_end_labels(path: "200:-200;200:-300;", boxes: target_boxes,
                                   source: [100, 100, 200, 100], target: [100, 300, 200, 100],
                                   mult: "0..*", end: :target)

    expect(result[:mult]).to eq([result[:last][0] + 8, result[:last][1] - 7])
  end
end
