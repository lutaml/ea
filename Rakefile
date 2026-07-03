# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

# RuboCop is intentionally not in the default task — the codebase has
# 1800+ pre-existing offenses that need a focused cleanup PR. CI's
# release pipeline runs `bundle exec rake` as a pre-publish sanity
# step, and a failing rubocop would block every release until the
# cleanup lands. Invoke `bundle exec rubocop` separately when needed.
begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
  # rubocop not installed (e.g., minimal install) — skip the task.
end

task default: :spec
