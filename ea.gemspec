# frozen_string_literal: true

require_relative "lib/ea/version"

Gem::Specification.new do |spec|
  spec.name = "ea"
  spec.version = Ea::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "Standalone Enterprise Architect data file parser"
  spec.description = "ea is a standalone Ruby gem for parsing Enterprise Architect data files (QEA format, Sparx XMI). It provides QEA database parsing, EA diagram rendering, and EA data validation. The UML bridge (Ea::Qea.to_uml) optionally requires the lutaml-uml gem."
  spec.homepage = "https://github.com/lutaml/ea"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/lutaml/ea"
  spec.metadata["changelog_uri"] = "https://github.com/lutaml/ea/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  excluded_prefixes = %w[
    bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml
    examples/ frontend/ reference-docs/ docs/ gemfiles/ memory/
    CLAUDE.md Rakefile
  ]
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?("TODO") ||
        f.start_with?(*excluded_prefixes)
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.licenses = ["BSD-2-Clause"]

  # Core dependencies — standalone parser needs only these.
  # `lutaml-uml` is intentionally NOT declared here: the gem is usable
  # standalone (QEA, XMI, Diagram, Transformations). The optional
  # UML bridge (Ea::Qea.to_uml) lazy-requires `lutaml/uml` inside the
  # method body and raises a clear error if the gem is not installed.
  spec.add_dependency "lutaml-model", "~> 0.8.159"
  spec.add_dependency "lutaml-path", "~> 0.2.4"
  spec.add_dependency "rubyzip", "~> 3.7"
  spec.add_dependency "sqlite3", "~> 2.10"
  # xmi 0.7.0 added nestedClassifier support and lowerValue-first
  # ordering; 0.7.2 additionally constrains lutaml-model below
  # 0.8.20, where Sparx type refs are silently dropped. 0.7.5 split
  # OwnedParameter's type into namespace-disjoint slots — the
  # exporter writes the classifier to classifier_type, which does
  # not exist before 0.7.5 (NoMethodError at serialization). All
  # three are required for faithful QEA→XMI export.
  spec.add_dependency "liquid", "~> 5"
  # XML via moxml (default adapter: leptris) — the gem parses every
  # document through it; moxml declares no adapter dependencies, so
  # the leptris gem is ours to pin.
  spec.add_dependency "leptris", "~> 1.9"
  spec.add_dependency "moxml", "~> 0.6"
  spec.add_dependency "thor", "~> 1.4"
  spec.add_dependency "xmi", "~> 0.7.5"

  # benchmark was removed from Ruby 4.0 default gems
  spec.add_dependency "benchmark", "~> 0.5"

  # Development-only — provides the UML bridge used by the spec suite.
  # The suite resolves 1.0.x (QeaToUml, spa, and the parity fixtures
  # run green against 1.0.3); the bridge targets the Lutaml::Uml 1.0
  # API surface, so the floor carries the major line only.
  spec.add_development_dependency "lutaml-uml", "~> 1.0"

  # Development-only — Rakefile's default task runs spec + rubocop.
  # Without this, `bundle exec rake` (invoked by metanorma/ci's
  # rubygems-release workflow during release) fails with
  # `LoadError: cannot load such file -- rubocop/rake_task`.
  spec.add_development_dependency "rubocop"
end
