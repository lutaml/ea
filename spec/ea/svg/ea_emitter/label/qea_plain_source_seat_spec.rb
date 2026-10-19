# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA plain source label path eligibility" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers
  include PlainSourceSeatHelpers

  it "seats a plain moved role when the original Path is absent" do
    result = plain_source_seat_result

    expect(result[:connector].style[:plain_source_seat]).to be(true)
    expect(result[:offset]).to eq([-106, -29])
  end

  it "keeps authored two-point Path labels at their explicit offsets" do
    result = plain_source_seat_result(path: "971:-537;834:-537;")

    expect(result[:connector].waypoints.size).to eq(2)
    expect(result[:connector].style[:plain_source_seat]).to be_nil
    expect(result[:offset]).to eq([-10, 22])
  end
end
