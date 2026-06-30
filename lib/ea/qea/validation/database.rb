# frozen_string_literal: true

module Ea
  module Qea
    module Validation
      module Database
        autoload :CircularReferenceValidator,
                 "ea/qea/validation/database/circular_reference_validator"
        autoload :OrphanValidator,
                 "ea/qea/validation/database/orphan_validator"
        autoload :ReferentialIntegrityValidator,
                 "ea/qea/validation/database/referential_integrity_validator"
      end
    end
  end
end
