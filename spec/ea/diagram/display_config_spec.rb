# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Diagram::DisplayConfig do
  describe ".from_style" do
    it "returns empty config for nil inputs" do
      config = described_class.from_style(style: nil, style_ex: nil)
      expect(config.show_attributes?).to be(true)
      expect(config.show_operations?).to be(true)
    end

    it "parses HideAtts=1 from Style" do
      config = described_class.from_style(style: "HideAtts=1", style_ex: nil)
      expect(config.show_attributes?).to be(false)
      expect(config.show_operations?).to be(true)
    end

    it "parses HideOps=1 from Style" do
      config = described_class.from_style(style: "HideOps=1", style_ex: nil)
      expect(config.show_operations?).to be(false)
      expect(config.show_attributes?).to be(true)
    end

    it "decouples SuppressFOC from feature visibility" do
      # SuppressFOC means "suppress foreign object content" (images,
      # OLE), NOT attribute/operation compartments. Even when set,
      # attributes and operations still render.
      config = described_class.from_style(style: nil, style_ex: "SuppressFOC=1")
      expect(config.suppress_foreign_object_content?).to be(true)
      expect(config.show_attributes?).to be(true)
      expect(config.show_operations?).to be(true)
    end

    it "parses ShowNotes=0 as hidden" do
      config = described_class.from_style(style: nil, style_ex: "ShowNotes=0")
      expect(config.show_notes?).to be(false)
    end

    it "parses AttPub=0 as hidden" do
      config = described_class.from_style(style: nil, style_ex: "AttPub=0")
      expect(config.show_public_attributes?).to be(false)
    end

    it "defaults AttPub to true when absent" do
      config = described_class.from_style(style: nil, style_ex: "OtherFlag=1")
      expect(config.show_public_attributes?).to be(true)
    end

    it "defaults ShowBorder to true when absent" do
      config = described_class.from_style(style: nil, style_ex: "")
      expect(config.show_border?).to be(true)
    end

    it "parses ShowBorder=0 as hidden" do
      config = described_class.from_style(style: nil, style_ex: "ShowBorder=0")
      expect(config.show_border?).to be(false)
    end

    it "parses multiple flags across Style + StyleEx" do
      config = described_class.from_style(style: "HideOps=1",
                                           style_ex: "AttPub=1;ShowNotes=0;Theme=:119")
      expect(config.show_operations?).to be(false)
      expect(config.show_attributes?).to be(true)
      expect(config.show_public_attributes?).to be(true)
      expect(config.show_notes?).to be(false)
    end
  end

  describe ".from_style_ex (backwards compat)" do
    it "delegates to from_style with nil Style" do
      config = described_class.from_style_ex("HideAtts=1")
      # HideAtts lives in Style, not StyleEx, so this should NOT
      # trigger attribute hiding via the back-compat shim.
      expect(config.show_attributes?).to be(true)
    end
  end

  describe "#to_style_ex" do
    it "preserves both Style and StyleEx flags in the merged output" do
      config = described_class.from_style(style: "HideAtts=1",
                                           style_ex: "AttPub=0;ShowNotes=1")
      merged = config.to_style_ex
      expect(merged).to include("HideAtts=1")
      expect(merged).to include("AttPub=0")
      expect(merged).to include("ShowNotes=1")
    end
  end

  describe "expanded PDATA flag matrix" do
    let(:empty) { described_class.from_style(style: nil, style_ex: nil) }

    it "HideEStereo=1 hides extended stereotypes (default shown)" do
      cfg = described_class.from_style(style: "HideEStereo=1;", style_ex: nil)
      expect(cfg.show_extended_stereotypes?).to be(false)
      expect(empty.show_extended_stereotypes?).to be(true)
    end

    it "ShowSN=1 shows sequence numbers (default off)" do
      cfg = described_class.from_style(style: "ShowSN=1;", style_ex: nil)
      expect(cfg.show_sequence_numbers?).to be(true)
      expect(empty.show_sequence_numbers?).to be(false)
    end

    it "OpParams=0 hides operation parameter types (default shown)" do
      cfg = described_class.from_style(style: "OpParams=0;", style_ex: nil)
      expect(cfg.show_operation_parameters?).to be(false)
      expect(empty.show_operation_parameters?).to be(true)
    end

    it "UseAlias=1 displays Alias instead of Name (default off)" do
      cfg = described_class.from_style(style: "UseAlias=1;", style_ex: nil)
      expect(cfg.use_alias?).to be(true)
      expect(empty.use_alias?).to be(false)
    end

    it "SuppCN=1 suppresses connector names (default shown)" do
      cfg = described_class.from_style(style: "SuppCN=1;", style_ex: nil)
      expect(cfg.show_connector_names?).to be(false)
      expect(empty.show_connector_names?).to be(true)
    end

    it "ShowCons=1 shows constraints compartment (default off)" do
      cfg = described_class.from_style(style: "ShowCons=1;", style_ex: nil)
      expect(cfg.show_constraints?).to be(true)
      expect(empty.show_constraints?).to be(false)
    end

    it "ScalePI=1 scales page indicators (default off)" do
      cfg = described_class.from_style(style: "ScalePI=1;", style_ex: nil)
      expect(cfg.scale_page_indicators?).to be(true)
      expect(empty.scale_page_indicators?).to be(false)
    end
  end
end
