# frozen_string_literal: true

# This file preserves backward compatibility for callers that
# reference `Ea::Transformers::QeaToXmi::GuidFormat`. The canonical
# implementation now lives at `Ea::GuidFormat` (shared across
# subsystems — DRY, MECE). See lib/ea/guid_format.rb.
module Ea
  module Transformers
    module QeaToXmi
      GuidFormat = ::Ea::GuidFormat
    end
  end
end
