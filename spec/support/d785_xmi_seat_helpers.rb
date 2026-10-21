# frozen_string_literal: true

require "tempfile"

module D785XmiSeatHelpers
  def d785_xmi_adapter(xml)
    Tempfile.create(["d785-target-seat", ".xmi"]) do |file|
      file.write(xml)
      file.flush
      return Ea::Sources::Xmi::Adapter.from_path(file.path)
    end
  end
end
