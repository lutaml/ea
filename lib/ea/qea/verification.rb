# frozen_string_literal: true

module Ea
  module Qea
    module Verification
      autoload :DocumentNormalizer,
               "ea/qea/verification/document_normalizer"
      autoload :StructureMatcher, "ea/qea/verification/structure_matcher"
      autoload :ElementComparator, "ea/qea/verification/element_comparator"
      autoload :ComparisonResult, "ea/qea/verification/comparison_result"
      autoload :DocumentVerifier, "ea/qea/verification/document_verifier"
    end
  end
end
