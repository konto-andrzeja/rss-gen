# frozen_string_literal: true

require 'sequel'

# Manages the shared SQLite database connection.
module Database
  DB_PATH = File.join(__dir__, 'db.sqlite3')

  class << self
    attr_reader :db

    def setup!(db_path: DB_PATH)
      @db = Sequel.sqlite(db_path, timeout: 5000)
    end
  end
end
