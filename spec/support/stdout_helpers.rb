# frozen_string_literal: true

module StdoutHelpers
  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end

RSpec.configure { |c| c.include(StdoutHelpers) }
