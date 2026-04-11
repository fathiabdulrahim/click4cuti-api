class EnablePgcrypto < ActiveRecord::Migration[8.1]
  def change
    # gen_random_uuid() is built into PostgreSQL 13+ — no extension required.
    # pgcrypto extension has OpenSSL compatibility issues with PG14 on macOS.
  end
end
