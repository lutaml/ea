# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Project phase / milestone from t_phase.
      #
      # Schema:
      #   (PhaseID INTEGER PRIMARY KEY, PhaseName TEXT,
      #    PhaseNotes TEXT, PhaseStart TEXT, PhaseEnd TEXT, ...)
      class EaPhase < BaseModel
        attribute :phase_id, :integer
        attribute :name, :string
        attribute :notes, :string
        attribute :start_date, :string
        attribute :end_date, :string

        def self.primary_key_column
          :phase_id
        end

        def self.table_name
          "t_phase"
        end

        COLUMN_MAP = {
          "PhaseID" => :phase_id,
          "PhaseName" => :name,
          "PhaseNotes" => :notes,
          "PhaseStart" => :start_date,
          "PhaseEnd" => :end_date
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end