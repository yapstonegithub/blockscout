defmodule Explorer.Repo.Migrations.AddDecompiledAndVerifiedFlagToAddresses do
  use Ecto.Migration

  def change do
    execute(
      """
      ALTER TABLE addresses
      ADD COLUMN IF NOT EXISTS decompiled BOOLEAN,
      ADD COLUMN IF NOT EXISTS verified BOOLEAN;
      """,
      """
      ALTER TABLE addresses
      DROP COLUMN IF EXISTS decompiled,
      DROP COLUMN IF EXISTS verified;
      """
    )

    execute(
      "CREATE INDEX IF NOT EXISTS addresses_decompiled_index ON addresses(decompiled)",
      "DROP INDEX IF EXISTS addresses_decompiled_index"
    )

    execute(
      "CREATE INDEX IF NOT EXISTS addresses_verified_index ON addresses(verified)",
      "DROP INDEX IF EXISTS addresses_verified_index"
    )
  end
end
