# frozen_string_literal: true

require "spec_helper"
require "ea/cli/app"
require "open3"
require "rbconfig"
require "tmpdir"

RSpec.describe "ea svg CLI command" do
  let(:app) { Ea::Cli::App.new }
  let(:xmi_fixture) { fixtures_path("basic.xmi") }

  after { FileUtils.rm_f([@out].compact) }

  it "renders a named diagram to a standalone SVG file" do
    @out = "/tmp/ea_svg_command_spec.svg"
    capture_stdout do
      app.invoke(:svg, ["Starter Object Diagram", xmi_fixture], output: @out)
    end
    expect(File.exist?(@out)).to be(true)
    contents = File.read(@out)
    expect(contents).to start_with("<?xml")
    expect(contents).to include("<svg")
  end

  it "raises Ea::Cli::Error for an unknown diagram name" do
    expect {
      capture_stdout do
        app.invoke(:svg, ["Does Not Exist", xmi_fixture],
                   output: "/tmp/ea_svg_unknown.svg")
      end
    }.to raise_error(Ea::Cli::Error, /not found/)
  end
end

RSpec.describe "ea svg --all CLI mode" do
  let(:app) { Ea::Cli::App.new }
  let(:xmi_fixture) { fixtures_path("basic.xmi") }

  after { FileUtils.rm_rf([@dir].compact) }

  it "renders every diagram in the source to its own SVG file" do
    @dir = "/tmp/ea_svg_all_spec"
    FileUtils.rm_rf(@dir)
    capture_stdout do
      app.invoke(:svg, [nil, xmi_fixture], all: true, output_dir: @dir)
    end
    files = Dir.glob(File.join(@dir, "*.svg"))
    expect(files.size).to be > 1
    sample = File.read(files.first)
    expect(sample).to start_with("<?xml")
    expect(sample).to include("<svg")
  end
end

RSpec.describe "ea svg/render CLI corrections" do
  let(:qea_fixture) { fixtures_path("basic.qea") }
  let(:name) { "Starter Object Diagram" }
  # Unframed height is 71, not 89: EA keeps no extra bottom margin below the
  # drawn content (X1 bottom-margin rule, confirmed against native EA exports:
  # basic canvas exact 16/22 -> 22/22). Framed output keeps its own padding.
  let(:unframed_box) { "0 0 325 71" }
  let(:framed_box) { "0 0 390 127" }

  around do |example|
    Dir.mktmpdir { |dir| @dir = dir; example.run }
  end

  def run_cli(*args)
    capture_stdout { Ea::Cli::App.start(args) }
  end

  it "accepts the documented `svg --all FILE` shape" do
    run_cli("svg", "--all", qea_fixture, "--output-dir=#{@dir}")
    expect(Dir.glob(File.join(@dir, "*.svg")).size).to be > 1
  end

  it "accepts `render --all FILE` and lists the written files without an output-formatter error" do
    listing = run_cli("render", "--all", qea_fixture, "--output-dir=#{@dir}")
    files = Dir.glob(File.join(@dir, "*.svg"))
    expect(files.size).to be > 1
    expect(listing).to include(files.first)
  end

  it "renders unframed by default and framed with --frame (svg)" do
    plain = File.join(@dir, "plain.svg")
    framed = File.join(@dir, "framed.svg")
    run_cli("svg", name, qea_fixture, "--output=#{plain}")
    run_cli("svg", name, qea_fixture, "--output=#{framed}", "--frame")
    expect(File.read(plain)).to include(%(viewBox="#{unframed_box}"))
    expect(File.read(framed)).to include(%(viewBox="#{framed_box}"))
  end

  it "renders framed with --frame (render)" do
    framed = File.join(@dir, "framed.svg")
    plain = File.join(@dir, "plain.svg")
    run_cli("render", name, qea_fixture, "--output=#{plain}")
    run_cli("render", name, qea_fixture, "--output=#{framed}", "--frame")
    expect(File.read(plain)).to include(%(viewBox="#{unframed_box}"))
    expect(File.read(framed)).to include(%(viewBox="#{framed_box}"))
  end

  it "renders framed with --frame (diagrams extract)" do
    plain = File.join(@dir, "plain.svg")
    framed = File.join(@dir, "framed.svg")
    run_cli("diagrams", "extract", qea_fixture, name, "--output=#{plain}")
    run_cli("diagrams", "extract", qea_fixture, name, "--output=#{framed}", "--frame")
    expect(File.read(plain)).to include(%(viewBox="#{unframed_box}"))
    expect(File.read(framed)).to include(%(viewBox="#{framed_box}"))
  end

  it "embeds framed SVGs in the SPA with --frame" do
    plain = File.join(@dir, "plain.html")
    framed = File.join(@dir, "framed.html")
    run_cli("spa", qea_fixture, "--output=#{plain}")
    run_cli("spa", qea_fixture, "--output=#{framed}", "--frame")
    expect(File.read(plain)).to include(unframed_box)
    expect(File.read(plain)).not_to include(framed_box)
    expect(File.read(framed)).to include(framed_box)
  end
end

RSpec.describe "ea diagrams extract CLI without --output" do
  it "writes the SVG next to the source without preloaded fileutils" do
    Dir.mktmpdir do |dir|
      FileUtils.cp(fixtures_path("basic.qea"), dir)
      script = <<~RUBY
        require "ea"
        require "ea/cli"
        Ea::Cli::Command::Diagrams.new(action: "extract",
          file: #{File.join(dir, "basic.qea").inspect}, name: "Domain Model").call
      RUBY
      out, status = Open3.capture2e(RbConfig.ruby, "-Ilib", "-e", script)
      expect(status.success?).to be(true), out
      expect(Dir[File.join(dir, "*.svg")]).not_to be_empty
    end
  end
end
