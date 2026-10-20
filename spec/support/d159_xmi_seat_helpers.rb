# frozen_string_literal: true

require "tempfile"

module D159XmiSeatHelpers
  def d159_xmi_adapter(xml)
    Tempfile.create(["d159-source-seat", ".xmi"]) do |file|
      file.write(xml)
      file.flush
      return Ea::Sources::Xmi::Adapter.from_path(file.path)
    end
  end
end
