# frozen_string_literal: true

require "spec_helper"
require "ea/cli/app"

# Specs for the `ea spa` CLI command. The native Ea::Model →
# Ea::Spa projection is the only pipeline; QEA and XMI sources
# follow the same path.
RSpec.describe "ea spa CLI command" do
  let(:app) { Ea::Cli::App.new }

  after do
    FileUtils.rm_f([@qea_out, @xmi_out, @bogus_out].compact)
  end

  def run_spa(file, output:, **opts)
    capture_stdout do
      app.invoke(:spa, [file], { output: output }.merge(opts))
    end
  end

  describe "QEA source" do
    it "generates a SPA from a QEA file" do
      @qea_out = "/tmp/ea_spa_qea_spec.html"
      run_spa(fixtures_path("basic.qea"), output: @qea_out)
      expect(File.exist?(@qea_out)).to be(true)
      expect(File.size(@qea_out)).to be > 1_000
    end

    it "embeds SPA data as window.__SPA_DATA__" do
      @qea_out = "/tmp/ea_spa_qea_embed_spec.html"
      run_spa(fixtures_path("basic.qea"), output: @qea_out)
      content = File.read(@qea_out)
      expect(content).to match(/<html/i)
      expect(content).to include("window.__SPA_DATA__")
    end
  end

  describe "XMI source" do
    it "generates a SPA from an XMI file" do
      @xmi_out = "/tmp/ea_spa_xmi_spec.html"
      run_spa(fixtures_path("basic.xmi"), output: @xmi_out)
      expect(File.exist?(@xmi_out)).to be(true)
      expect(File.size(@xmi_out)).to be > 1_000
    end

    it "embeds SPA data as window.__SPA_DATA__" do
      @xmi_out = "/tmp/ea_spa_xmi_embed_spec.html"
      run_spa(fixtures_path("basic.xmi"), output: @xmi_out)
      content = File.read(@xmi_out)
      expect(content).to include("window.__SPA_DATA__")
    end
  end

  describe "mode handling" do
    it "rejects an unsupported mode" do
      @bogus_out = "/tmp/ea_spa_bogus.html"
      expect {
        capture_stdout do
          app.invoke(:spa, [fixtures_path("basic.qea")],
                     mode: "bogus", output: @bogus_out)
        end
      }.to raise_error(ArgumentError, /Unknown SPA mode/)
    end
  end
end
