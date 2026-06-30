# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      module Emitters
        # Common interface for all QEA-record → XML emitters.
        #
        # Subclasses implement {#emit}. Emitters receive a `record` (a QEA
        # model instance) and a {Context} providing writer + db + lookups.
        # They emit XML by calling methods on `ctx.writer` directly.
        class BaseEmitter
          def emit(_record, _ctx)
            raise NotImplementedError,
                  "#{self.class}#emit not implemented"
          end

          private

          # Sort by the record's declared sort_position then by name for
          # stable output. Each model class declares its own sort_position
          # (tpos for t_package/t_object, pos for t_attribute/t_operation).
          def sorted_by_position(records)
            records.sort_by { |r| [r.sort_position, r.name.to_s] }
          end
        end
      end
    end
  end
end
