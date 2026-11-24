# Error Handling Checks

Silent failures turn a crash into wrong data that nobody notices (from ECC silent-failure-hunter).

- **Swallowed errors** — empty `catch {}`, `catch` that only logs then continues as if it succeeded
- **Hiding fallbacks** — `.catch(() => [])`, `?? 0`, `|| {}` on a failed call, so callers can't tell "empty" from "failed"
- **Lost cause** — `throw new Error('failed')` dropping the original error/stack, or rethrowing a generic type
- **Floating promises** — async call not awaited/returned, so its rejection is never handled
- **Partial writes** — multi-step DB/external writes without a transaction or compensation when a later step fails
- **Weak logs** — error logged without the id/input needed to debug it, or at the wrong level
