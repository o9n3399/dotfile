# Database & Migration Checks

From ECC database-reviewer, applied only when the diff touches entities, migrations or queries.

- **Migration safety** — `down` actually reverts `up`; NOT NULL column added to a populated table without a default/backfill
- **Destructive changes** — column/table drop or rename that running code or other services still read
- **Locking** — index creation or column type change on a large table that locks writes (prefer `CONCURRENTLY` on Postgres)
- **Entity/migration drift** — entity field changed with no migration, or migration with no entity change
- **Constraints** — uniqueness/foreign keys enforced only in code where concurrent requests can break them
- **Raw SQL** — string-built queries instead of parameters; queries filtering soft-deleted rows inconsistently
