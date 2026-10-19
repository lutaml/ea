# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA source Property roles with a persisted alignment-zero box leaving down" do
  include LabelUpwardPropertyHelpers
  include LabelDownAlignmentHelpers

  it "seats the role at the downward Property seat with a left-aligned stereotype" do
    down_alignment_records.each do |record|
      positions = down_alignment_positions(record)

      expect(positions["+#{record[:role]}"]).to eq(record[:expected]), record[:role]
      expect(positions["«property»"]).to eq([record[:expected][0], record[:expected][1] + 12]), record[:role]
    end
  end

  it "keeps unsupported routes, absent boxes and custom presentations at their stored offsets" do
    down_alignment_records.product(down_alignment_controls).each do |record, options|
      positions = down_alignment_positions(record, options)

      expect(positions["+#{record[:role]}"]).to eq(down_alignment_stored(record, options)),
                                                "#{record[:role]} #{options.keys}"
    end
  end
end
