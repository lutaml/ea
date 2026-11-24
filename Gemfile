# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Sibling checkouts override the published gems when present next door
# (monorepo-style development — same convention as lutaml-uml). One
# declaration per gem: path source if the checkout exists, rubygems
# otherwise. There is deliberately no env-var switch; to test the
# CI-resolved published versions against local sibling checkouts use:
#
#   BUNDLE_GEMFILE=gemfiles/published.gemfile bundle install
#
# Out-of-tree checkouts (e.g. claricle emf/emfsvg, fontist) join the
# convention via symlink instead of hardcoded $HOME paths here:
#
#   ln -s ~/src/claricle/emf ../emf
#   ln -s ~/src/claricle/emfsvg ../emfsvg
#   ln -s ~/src/fontist/fontist ../fontist
#
# emf/emfsvg/fontist are consumer-side dependencies by design (lazy
# requires, never in the gemspec); they are listed here because the
# dev suite exercises them.
%w[lutaml-uml canon xmi emfsvg emf fontist].each do |gem_name|
  path = File.expand_path("../#{gem_name}", __dir__)
  if File.directory?(path)
    gem gem_name, path: path
  else
    gem gem_name
  end
end

gem "rake"
gem "rspec", "~> 3.0"
