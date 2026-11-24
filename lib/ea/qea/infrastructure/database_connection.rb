# frozen_string_literal: true

require "sqlite3"
require "tmpdir"

module Ea
  module Qea
    module Infrastructure
      # DatabaseConnection manages the SQLite database connection lifecycle
      # for QEA files (Enterprise Architect SQLite databases).
      #
      # @example Connect to a QEA file
      #   conn = DatabaseConnection.new("model.qea")
      #   conn.connect
      #   # ... use connection
      #   conn.close
      #
      # @example Using with_connection block
      #   conn = DatabaseConnection.new("model.qea")
      #   conn.with_connection do |db|
      #     # ... use db
      #   end
      class DatabaseConnection
        attr_reader :file_path, :connection

        SQLITE_MAGIC = "SQLite format 3\x00"
        ZIP_MAGIC = "PK\x03\x04"

        # Initialize a new database connection
        #
        # @param file_path [String] Path to the .qea file
        # @raise [ArgumentError] if file_path is nil or empty
        def initialize(file_path)
          if file_path.nil? || file_path.empty?
            raise ArgumentError,
                  "file_path cannot be nil or empty"
          end

          @file_path = file_path
          @connection = nil
          @extracted_path = nil
        end

        # Connect to the database
        #
        # ZIP-compressed QEA archives are extracted to a temporary file
        # first (removed when the connection closes).
        #
        # @return [SQLite3::Database] The database connection
        # @raise [Errno::ENOENT] if the file does not exist
        # @raise [Ea::Error] if the file is neither SQLite nor a ZIP archive
        # @raise [SQLite3::Exception] if connection fails
        def connect
          unless File.exist?(@file_path)
            raise Errno::ENOENT, "QEA file not found: #{@file_path}"
          end

          @connection = SQLite3::Database.new(openable_path, readonly: true)
          @connection.results_as_hash = true
          @connection
        end

        # Close the database connection
        #
        # @return [void]
        def close
          return unless @connection

          @connection.close
          @connection = nil
          remove_extracted_file
        end

        # Check if the connection is open
        #
        # @return [Boolean] true if connection is open
        def connected?
          !@connection.nil? && !@connection.closed?
        end

        # Execute a block with an active connection
        #
        # This method ensures the connection is properly opened and closed.
        # If a connection already exists, it reuses it. Otherwise, it creates
        # a new connection and closes it after the block executes.
        #
        # @yield [SQLite3::Database] The database connection
        # @return [Object] The result of the block
        # @raise [Errno::ENOENT] if the file does not exist
        # @raise [SQLite3::Exception] if connection fails
        #
        # @example
        #   conn = DatabaseConnection.new("model.qea")
        #   result = conn.with_connection do |db|
        #     db.execute("SELECT COUNT(*) FROM t_object")
        #   end
        def with_connection
          should_close = !connected?

          begin
            connect unless connected?
            yield @connection
          ensure
            close if should_close
          end
        end

        private

        # Route to the raw file when it is a SQLite database, or to a
        # fresh temporary extraction when it is a ZIP archive.
        # @return [String] path SQLite can open
        # @raise [Ea::Error] on any other file content
        def openable_path
          header = File.open(@file_path, "rb") { |f| f.read(16) } || ""

          if header.start_with?(SQLITE_MAGIC)
            @file_path
          elsif header.start_with?(ZIP_MAGIC)
            @extracted_path = extract_sqlite_from_zip
          else
            raise Ea::Error,
                  "#{@file_path} is not a QEA file: expected a SQLite " \
                  "database or a ZIP archive of one"
          end
        end

        # @return [String] path to the extracted SQLite file
        # @raise [Ea::Error] when no SQLite database entry is in the archive
        def extract_sqlite_from_zip
          require "zip"

          entry = sqlite_zip_entry or
            raise Ea::Error,
                  "#{@file_path} is a ZIP archive but contains no " \
                  "SQLite database entry"

          path = File.join(Dir.tmpdir, "ea-#{Process.pid}-#{Time.now.to_i}-" \
                                      "#{File.basename(@file_path)}.sqlite")
          File.binwrite(path, entry.get_input_stream.read)
          path
        end

        def sqlite_zip_entry
          Zip::File.open(@file_path) do |zip_file|
            files = zip_file.entries.select(&:file?)
            named = files.select do |e|
              e.name.end_with?(".qea", ".sqlite", ".eap")
            end
            (named.max_by(&:size) || files.max_by(&:size))
          end
        end

        def remove_extracted_file
          return unless @extracted_path

          File.delete(@extracted_path)
        rescue Errno::ENOENT
          nil
        ensure
          @extracted_path = nil
        end
      end
    end
  end
end
