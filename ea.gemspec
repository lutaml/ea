# frozen_string_literal: true

require_relative "lib/ea"

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
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Core dependencies — standalone parser needs only these.
  # `lutaml-uml` is intentionally NOT declared here: the gem is usable
  # standalone (QEA, XMI, Diagram, Transformations). The optional
  # UML bridge (Ea::Qea.to_uml) lazy-requires `lutaml/uml` inside the
  # method body and raises a clear error if the gem is not installed.
  spec.add_dependency "lutaml-model"
  spec.add_dependency "lutaml-path"
  spec.add_dependency "sqlite3"
  spec.add_dependency "rubyzip"
  spec.add_dependency "xmi", "~> 0.6", ">= 0.6.0"
  spec.add_dependency "nokogiri", "~> 1.18"
  spec.add_dependency "liquid"
  spec.add_dependency "thor", "~> 1.4"

  # benchmark was removed from Ruby 4.0 default gems
  spec.add_dependency "benchmark"

  # Development-only — provides the UML bridge used by the spec suite.
  # The bridge targets Lutaml::Uml::Document / UmlClass / Association /
  # etc., all of which remain on those names from 0.2 through 0.5+
  # (no rename happened despite the major-version bump cadence). Pinned
  # to 0.5.2+ to pick up the WelcomeView custom-logo fix
  # (lutaml/lutaml-uml#119) exercised indirectly via the SPA command.
  spec.add_development_dependency "lutaml-uml", ">= 0.5.2"

  # Development-only — Rakefile's default task runs spec + rubocop.
  # Without this, `bundle exec rake` (invoked by metanorma/ci's
  # rubygems-release workflow during release) fails with
  # `LoadError: cannot load such file -- rubocop/rake_task`.
  spec.add_development_dependency "rubocop"
end
