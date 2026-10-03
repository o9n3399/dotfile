# Performance Checks

- **N+1 queries** — DB/API call inside a loop instead of batch/join
- **Unbounded work** — queries without limit/pagination, loading whole tables/files into memory
- **Missing indexes** — new query filters/sorts on columns without an index (check migrations)
- **Blocking** — sync I/O or CPU-heavy work on a request path / event loop
- **Sequential awaits** — independent async calls awaited one by one instead of in parallel
- **Repeated work** — same expensive computation or fetch per request with no cache
- **Leaks** — listeners/intervals/connections opened without cleanup
