# frozen_string_literal: true

module Ea
  module Model
    # Id-keyed lookup in which a package stored under `EAPK_<guid>`
    # also answers to `EAID_<guid>`, without a second entry: `values`
    # lists each package once.
    class PackageAliasIndex < Hash
      def [](id)
        super || package_alias(id)
      end

      private

      def package_alias(id)
        return unless id.is_a?(String) && id.start_with?("EAID_")

        fetch("EAPK_#{id[5..]}", nil)
      end
    end
  end
end
