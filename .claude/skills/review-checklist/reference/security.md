# Security Checks

- **Injection** — SQL/NoSQL built by string concat, shell commands with user input, template injection
- **AuthN/AuthZ** — new endpoint without guard, missing ownership check (IDOR), role check on client only
- **Input validation** — unvalidated request body/query/params, missing whitelist/strip of unknown fields
- **Secrets** — hardcoded keys/tokens, secrets in logs or error messages, `.env` committed
- **Data exposure** — returning full entities (password hash, internal fields), verbose errors to clients
- **Crypto** — weak hashing for passwords (md5/sha1), `Math.random` for tokens, disabled TLS verification
- **SSRF / path traversal** — user-controlled URLs fetched server-side, user input in file paths
- **Deserialization** — `eval`, unsafe YAML/pickle load, prototype pollution via object merge
- **Dependencies** — new package that is unmaintained or typo-squatted
