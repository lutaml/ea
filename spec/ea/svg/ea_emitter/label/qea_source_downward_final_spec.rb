# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA persisted downward source Property boxes" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers
  include LabelDownwardFinalHelpers

  %w[parent shape].each do |name|
    it "matches the native downward seat for #{name}" do
      record = downward_final_records.find { |item| item[:role] == name }
      result = downward_final_labels(record)
      role, stereo = result[:texts].select { |text| ["+#{record[:role]}", "«property»"].include?(text[:text]) }
      expected = result[:first].zip(record[:delta]).map(&:sum)

      expect([role[:x], role[:y]]).to eq(expected), record[:role]
      expect([stereo[:x], stereo[:y]]).to eq([expected[0], expected[1] + 12]), record[:role]
      expect(result[:mult]).to eq([result[:first][0] + 8, result[:first][1] + 15]), record[:role]
    end
  end

  it "preserves plain role seats on the same persisted boxes" do
    downward_final_records.each do |record|
      result = downward_final_labels(record, stereotype: "")
      role = result[:texts].find { |text| text[:text] == "+#{record[:role]}" }

      delta = record[:role] == "parent" ? [49, -14] : [106, 12]
      expect([role[:x], role[:y]]).to eq(result[:first].zip(delta).map(&:sum))
    end
  end
end
