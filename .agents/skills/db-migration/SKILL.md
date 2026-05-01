---
name: db-migration
description: Create and run database migrations safely with UP + DOWN scripts. Use this skill whenever a schema change is needed — adding tables, columns, indexes, constraints, or seed data. Works with EF Core (C# API) and raw SQL. Trigger on "migration", "schema change", "add column", "alter table", "database update", "new table".
---

# Skill: DB Migration

## Steps

1. **Check current migrations**
   - For API (EF Core): `dotnet ef migrations list --project services/api`
   - For shared / raw SQL: inspect `migrations/` directory and note the latest numbered file
2. **Create the migration file**
   - EF Core (API service): `dotnet ef migrations add <MigrationName> --project services/api`
   - Raw SQL (shared): create a new file following the naming convention `YYYYMMDDHHMMSS_description.sql`
3. **Write the UP migration**
   - Add all DDL/DML statements
4. **Write the DOWN migration**
   - Always include a DOWN / rollback section that reverses the UP
   - Ensure the DOWN is safe and idempotent (use `IF EXISTS`, `IF NOT EXISTS`)
5. **Run the migration locally**
   - EF Core: `dotnet ef database update --project services/api`
   - Raw SQL: execute against local Postgres via `psql` or a runner script
6. **Verify status**
   - Confirm the migration applied: check table schema, run a quick SELECT
   - Run existing tests to ensure nothing broke

## Output Format

```
Migration: <name>
Type:      EF Core | Raw SQL
Status:    Applied | Pending | Failed
Tables:    <affected tables>
Rollback:  Verified | Not Verified
```

## Rules

- Always include a DOWN / rollback migration
- Migrations must be idempotent (safe to run more than once)
- Test on local database before marking as complete
- Never modify a migration that has already been applied to a shared environment
- One logical change per migration file
- Use descriptive names, not generic ones like "Update1"
