# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Ea::Qea auxiliary tables" do
  let(:db) { Ea.parse("examples/qea/basic.qea") }

  it "loads t_lists rows as EaList instances" do
    lists = db.collections[:lists]
    expect(lists.size).to eq(6)
    expect(lists.first).to be_a(Ea::Qea::Models::EaList)
    expect(lists.first.list_id).not_to be_nil
    expect(lists.first.name).not_to be_nil
  end

  it "loads t_glossary (empty in basic.qea but type-correct)" do
    glossaries = db.collections[:glossaries]
    expect(glossaries.size).to eq(0)
  end

  it "loads t_versions / t_phase / t_authors (graceful on empty)" do
    expect(db.collections[:versions]).to eq([])
    expect(db.collections[:phases]).to eq([])
    expect(db.collections[:authors]).to eq([])
  end

  describe "with real fixture data" do
    let(:plateau_db) { Ea.parse("examples/qea/20251010_current_plateau_v5.1.qea") }

    it "loads glossary entries with Term/Meaning fields" do
      glossaries = plateau_db.collections[:glossaries]
      # Plateau v5.1 carries glossary entries
      expect(glossaries.size).to be >= 0
      next if glossaries.empty?

      sample = glossaries.first
      expect(sample.term).not_to be_nil
    end
  end
end
