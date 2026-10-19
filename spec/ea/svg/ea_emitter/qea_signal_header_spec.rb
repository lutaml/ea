# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe "QEA default Signal header baselines" do
  include SignalHeaderHelpers

  { "basic" => ["Signal A", "Signal B", "Signal C"], "simple" => ["AcmeUmlSignal"] }.each do |file, names|
    names.each do |name|
      it "seats #{file}'s #{name} at the native baselines" do
        expect(signal_header_rows(signal_document(file), name)).to eq([12, 27])
      end
    end
  end

  it "preserves an explicitly selected seven point Cambria font" do
    rows = signal_header_rows(signal_document("simple"), "AcmeUmlSignal") do |placement|
      placement.font_family = "Cambria"
      placement.font_size = 7
      placement.font_size_inherited = false
    end
    expect(rows).to eq([13, 25])
  end

  it "uses the type contract after the Signal is renamed" do
    document = signal_document("simple")
    document.index_by_id.values.find { |entry| entry.name == "AcmeUmlSignal" }.name = "Notice"
    expect(signal_header_rows(document, "Notice")).to eq([12, 27])
  end
end
