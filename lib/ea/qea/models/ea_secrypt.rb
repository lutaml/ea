# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Encryption metadata from t_secrypt. Records whether parts of
      # the QEA are encrypted and what algorithm was used.
      class EaSecrypt < BaseModel
        attribute :secrypt_id, :integer
        attribute :ea_object_id, :integer
        attribute :encrypt, :string
        attribute :password_hash, :string

        def self.primary_key_column
          :secrypt_id
        end

        def self.table_name
          "t_secrypt"
        end

        COLUMN_MAP = {
          "SecryptID" => :secrypt_id,
          "Object_ID" => :ea_object_id,
          "PasswordHash" => :password_hash
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end
