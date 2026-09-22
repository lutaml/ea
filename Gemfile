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
  elsif sibling_gem == "lutaml-uml"
    # Mirror the gemspec constraint. Unconstrained, the resolver jumps
    # to the stale 1.0.0 major (2024), whose lutaml meta-gem dependency
    # (lutaml 0.9.8) drags in expressir 1.4.x — whose native extension
    # no longer compiles against rice 4.12 (rice ~> 4.2 is expressir
    # 1.4.3's own runtime dep). That broke the release preflight
    # (lutaml/ea#43) until the expressir pin in #44 masked it.
    gem sibling_gem, "~> 0.5", ">= 0.5.2"
  else
    gem sibling_gem
  end
end

gem "rake"
gem "rspec", "~> 3.0"
