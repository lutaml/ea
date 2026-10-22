# frozen_string_literal: true

require "spec_helper"

# A reversed link seats the source labels left of the anchor; a long role
# must stop at the same x floor the other leftward seats use.
RSpec.describe Ea::Svg::EaEmitter::Label::EndLabel do
  include EndLabelLeftSeatHelpers

  it "keeps a role that fits at its seat left of the anchor" do
    expect(left_seat_label_xs(described_class, "items", [200, 100]).first).to be_between(3, 200)
  end

  it "clamps a role wider than the room left of the anchor to the minimum role x" do
    expect(left_seat_label_xs(described_class, "x" * 200, [200, 100])).to all(be >= described_class::MIN_ROLE_X)
  end
end
