# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Sibling-repo path dependencies — used during local development when
# the sibling checkout exists (monorepo-style workflow). In CI and for
# gem install, fall back to the published rubygems versions.
#
# Set EA_FORCE_RUBYGEMS=1 to test the CI-resolved versions locally.
%w[lutaml-uml canon xmi emfsvg emf].each do |sibling_gem|
  sibling_path = File.expand_path("../#{sibling_gem}", __dir__)
  actual_path = sibling_gem == "emfsvg" ? File.expand_path("~/src/claricle/emfsvg") : sibling_path
  actual_path = sibling_gem == "emf" ? File.expand_path("~/src/claricle/emf") : actual_path
  if actual_path && File.directory?(actual_path) && ENV["EA_FORCE_RUBYGEMS"] != "1"
    gem sibling_gem, path: actual_path
  else
    gem sibling_gem
  end
end

gem "rake"
gem "rspec", "~> 3.0"

# The release preflight resolves the bundle fresh and something in the
# GitHub Packages index pulls expressir 1.4.3, whose native extension
# no longer compiles against rice 4.12 (Rice 4 API break) — the release
# cannot cut. expressir 2.x is the rice-free line; pin it so the
# resolution cannot land on 1.4.x. If a dependency really needs 1.4,
# bundler will now name it instead of failing in a C compiler.
gem "expressir", "~> 2.4"
