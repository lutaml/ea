# frozen_string_literal: true

require "spec_helper"

# Label seats measured against the native Plateau v5.1 SVG export once repeated
# texts were counted (X5b): every expected position below is the native one
# (34FF671B native 630,584 + canvas 40,0; 5038EEE3 native 640,456 + canvas 30,70).
RSpec.describe "Issue 135 stereotype-only Property target end" do
  include LabelUpwardPropertyHelpers
  include Issue135X5bLabelHelpers

  describe "a Property stereotype with no role or multiplicity on a target end" do
    it "seats the stereotype at the unflipped box corner, 8px left and 15px below (34FF671B)" do
      box = { "ox" => 22, "oy" => -31, "cx" => 57, "cy" => 16, "alignment" => 1 }

      expect(stereotype_only_target_positions([704, 600], box)).to eq("«property»" => [670, 584])
    end

    it "seats it the same way on a wider box (5038EEE3)" do
      box = { "ox" => -38, "oy" => -7, "cx" => 90, "cy" => 16, "alignment" => 1 }

      expect(stereotype_only_target_positions([764, 518], box)).to eq("«property»" => [670, 526])
    end

    it "keeps the flipped box seat for boxes that are not one centred line" do
      box = { "ox" => 22, "oy" => -31, "cx" => 57, "cy" => 31, "alignment" => 1 }

      expect(stereotype_only_target_positions([704, 600], box)).to eq("«property»" => [726, 631])
    end
  end
end

RSpec.describe "Issue 135 upward and rightward Property cluster centring" do
  include LabelUpwardPropertyHelpers
  include Issue135X5bLabelHelpers

  describe "an upward source Property cluster in a centred stored box" do
    it "keeps the cluster's left edge on the stereotype and centres the shorter role over it (E7AABA98)" do
      result = centred_upward_positions({ "ox" => -11, "oy" => -24, "cx" => 57, "cy" => 31, "alignment" => 1 })

      expect(result.fetch("+address")[0] - result.fetch("«property»")[0]).to eq(4)
      width = Ea::Fonts::Metrics.text_length("+address", 7, family: "Cambria")
      expect(result.fetch("+address")[0]).to eq(384 - 11 - 60 - width + 4)
    end

    it "leaves a left-aligned box on the role's own seat" do
      result = centred_upward_positions({ "ox" => -11, "oy" => -24, "cx" => 57, "cy" => 31, "alignment" => 0 })

      expect(result.fetch("+address")[0]).to eq(result.fetch("«property»")[0])
    end
  end

  describe "a rightward phantom Property source" do
    it "centres the stereotype under the wider role (0BE81AC5)" do
      result = rightward_phantom_positions({ phantom_outline: true })

      expect(result.fetch("«property»")[0] - result.fetch("+boundedBy")[0]).to eq(4)
    end

    it "keeps the role seat and a left stereotype for an unflagged connector" do
      result = rightward_phantom_positions({ lwidth: "2" })

      expect(result.fetch("«property»")[0]).to eq(result.fetch("+boundedBy")[0])
    end
  end
end

# 0BE81AC5: the three boundedBy phantoms have UMLDI role bounds but no saved
# link row; the native stereotype is centred under the 52px role, 4px right.
RSpec.describe "XMI phantom Property stereotype centring" do
  let(:source) { Xmi0beBoundedByLabelsHelpers.source(fixtures_path("issue135_route_style/0be-boundedby-umldi.xmi")) }

  it "seats each «property» line 4px right of its +boundedBy role" do
    roles = Xmi0beBoundedByLabelsHelpers.render_texts(*source, "+boundedBy")
    stereotypes = Xmi0beBoundedByLabelsHelpers.render_texts(*source, "«property»")

    expect(stereotypes.map { |x, _| x.to_f - 4 }).to eq(roles.map { |x, _| x.to_f })
  end
end

# 5038EEE3 native 269,227 in the diagram frame, 299,297 in the canvas frame
# used here (role-less target end, leg arriving sloped from the right).
RSpec.describe "Issue 135 sloped rightward role-less target multiplicity" do
  include LabelUpwardPropertyHelpers
  include Issue135X5bLabelHelpers

  let(:text_box) { { "ox" => -26, "oy" => -72, "cx" => 79, "cy" => 16, "alignment" => 1 } }
  let(:mult_box) { { "ox" => -54, "oy" => -85, "cx" => 19, "cy" => 16, "alignment" => 1 } }

  it "takes the rightward corner seat for a Property source (5038EEE3)" do
    expect(sloped_target_mult("property", text_box, mult_box)).to eq([299.0, 297.0])
  end

  it "keeps the previous seat when the source is not a Property" do
    expect(sloped_target_mult(nil, text_box, mult_box)).not_to eq([299.0, 297.0])
  end
end

# 5038EEE3 native 386,612 in the diagram frame, 416,682 in the canvas frame.
RSpec.describe "Issue 135 vertical tree target multiplicity" do
  include LabelUpwardPropertyHelpers
  include Issue135X5bLabelHelpers

  let(:text_box) { { "ox" => -26, "oy" => -123, "cx" => 71, "cy" => 31, "alignment" => 1 } }
  let(:mult_box) { { "ox" => -52, "oy" => -31, "cx" => 19, "cy" => 16, "alignment" => 1 } }

  it "seats a moved LV tree target at its unflipped corner" do
    expect(tree_target_mult({ tree: "LV" }, text_box, mult_box)).to eq([416.0, 682.0])
  end

  it "keeps the flipped moved-label seat for other routes" do
    expect(tree_target_mult({}, text_box, mult_box)).not_to eq([416.0, 682.0])
  end
end
