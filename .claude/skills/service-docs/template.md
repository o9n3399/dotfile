# <service-name>

<one or two lines: what this service owns and who calls it>

## Run Locally

```sh
<install / start command from the manifest or Makefile>
```

Requires: <DB, broker, other services>. Source: `<manifest:line>`

Deploy: <Dockerfiles / compose files / CI pipeline and what each is for>

## Modules

| Module | Responsibility | Path |
|--------|----------------|------|
| <module> | <one line> | `<path>` |

## Configuration

| Variable | Purpose | Default | Required | In `.env.example` |
|----------|---------|---------|----------|-------------------|
| `<NAME>` | <what it controls> | <non-secret default or —> | yes/no | yes/no |

Source: `<config file:line>`

## API

Base path: `<global prefix>` · Auth: <global guard / gateway, and exceptions> · Full reference: <Swagger/OpenAPI URL if generated>

### <module or controller>

| HTTP | Message pattern | Purpose | Auth |
|------|-----------------|---------|------|
| `GET /<path>` | `<subject>` | <what it does> | <guard/permission or public> |

Source: `<controller:line>`

## Messaging

| Direction | Broker | Topic / Queue / Subject | Payload | Source |
|-----------|--------|-------------------------|---------|--------|
| publishes | <RabbitMQ / Kafka / NATS> | `<name>` | `<type>` | `<file:line>` |

## Data

| Store | Used for | Entities / tables | Source |
|-------|----------|-------------------|--------|
| <Postgres / ClickHouse / Redis> | <purpose> | <list> | `<path>` |

Migrations: `<path>` (<count>)

## Dependencies

| Service | Via | Used for | Config / subject |
|---------|-----|----------|------------------|
| <service> | <HTTP / NATS / gRPC> | <calls made> | `<BASE_URL var or subject prefix>` |

## Key Flows

### <flow name>

<entry handler> → <steps with entities/status changes> → <events published>. Source: `<file:line>`

## Operations

- Health: `<endpoint>`
- Service discovery / gateway: <Consul, Kong, … if registered>
- Logs / metrics: <where>
- Known issues: <only if found in code or existing docs>
