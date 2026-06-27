# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Ea::Qea standalone API" do
  describe "standalone parsing (no lutaml-uml required for core)" do
    it "provides Ea::Qea.load as the standalone entry point" do
      expect(Ea::Qea).to respond_to(:load)
    end

    it "provides Ea::Qea.load_database" do
      expect(Ea::Qea).to respond_to(:load_database)
    end

    it "provides Ea::Qea.to_uml as the UML bridge" do
      expect(Ea::Qea).to respond_to(:to_uml)
    end
  end

  describe "Ea::Qea.to_uml" do
    it "raises an error when called with nil database" do
      expect { Ea::Qea.to_uml(nil) }.to raise_error(NoMethodError)
    end
  end

  describe "Ea::Qea.parse" do
    it "raises an error for non-existent files" do
      expect { Ea::Qea.parse("/nonexistent/file.qea") }
        .to raise_error(Errno::ENOENT)
    end
  end

  describe "standalone core with real fixture" do
    let(:qea_path) { fixtures_path("basic.qea") }

    it "loads EA database standalone", :requires_fixtures do
      database = Ea::Qea.load(qea_path)

      expect(database).to be_a(Ea::Qea::Database)
      expect(database.packages).to be_an(Array)
    end

    it "converts to UML via to_uml bridge", :requires_fixtures do
      database = Ea::Qea.load(qea_path)
      document = Ea::Qea.to_uml(database)

      expect(document).to be_a(Lutaml::Uml::Document)
      expect(document.packages).to be_an(Array)
    end
  end
end
