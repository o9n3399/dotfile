---
name: nestjs-convention
description: Use when writing or reviewing NestJS service code in bchh/icd/tst repos - get-list DTOs, repository query files, handle() services, numeric math, NATS calls, file naming.
user-invocable: false
---

# NestJS convention

Apply these conventions to the file or component being worked on.

## Rules

### 1. Get-list DTOs must extend PaginationQuery

All DTOs used for list/paginated endpoints must extend `PaginationQuery`, not `BaseDto`.

```ts
// ✅ correct
import { PaginationQuery } from '@utils/pagination.query';
export class StockGetListRequestDto extends PaginationQuery {}

// ❌ wrong
import { BaseDto } from '@core/dto/base.dto';
export class StockGetListRequestDto extends BaseDto {}
```

### 2. Extract IDs using ArrayHelper

When collecting unique IDs from a data array or payload, always use `ArrayHelper.getUniqueValues()`. Never use the `[...new Set(data.map(...).filter(Boolean))]` pattern.

```ts
// ✅ correct
import { ArrayHelper } from '@helper/array.helper';
const { itemId: itemIds, warehouseId: warehouseIds } = ArrayHelper.getUniqueValues(data, ['itemId', 'warehouseId']);

// ❌ wrong
const itemIds = [...new Set(data.map((r) => r.itemId).filter(Boolean))];
const warehouseIds = [...new Set(data.map((r) => r.warehouseId).filter(Boolean))];
```

For nested fields (e.g. inside `attributes`), flatten first then apply:
```ts
const mapped = data.map((r) => ({ ...r, locatorId: r.attributes?.locator_id }));
const { itemId: itemIds, locatorId: locatorIds } = ArrayHelper.getUniqueValues(mapped, ['itemId', 'locatorId']);
```

### 3. All handle() parameters must have explicit types

Every `handle()` method — and every public method in a service class — must have explicit TypeScript types on all parameters. No implicit `any`.

```ts
// ✅ correct
async handle(request: StockGetListRequestDto): Promise<any> {}

// ❌ wrong
async handle(request: any): Promise<any> {}
async handle(request): Promise<any> {}
```

### 4. Split repository queries into the query/ folder

Query logic must not live inline in the repository class. Each query is extracted to its own file under `<repository>/query/`, with the repository method delegating via a single `return` call.

```
database/repository/stock/
  query/
    stock.get-list.query.ts          ← query logic here
    stock.get-putaway.query.ts
    stock.upsert.query.ts
  stock.repository.ts                ← thin: return stockGetListQuery(request, this.entityRepository)
```

```ts
// stock.repository.ts — ✅ correct
async getList(request: StockGetListRequestDto): Promise<{ data: any[]; count: number }> {
  return stockGetListQuery(request, this.entityRepository);
}

// stock.repository.ts — ❌ wrong (query logic inline)
async getList(request: any): Promise<any> {
  const qb = this.entityRepository.createQueryBuilder('s');
  // ... 30 lines of query logic
}
```

### 5. Get-list service structure

Every get-list service must follow this three-method structure:

- **`handle(request)`** — main entry point: fetches paginated data from repository, calls `getExtraInfo`, calls `makeResponse`, returns `ResponseBuilder` result.
- **`getExtraInfo(data)`** — fetches all related entities needed to enrich the list (items, warehouses, locators, units, etc.) by extracting IDs from `data` with `ArrayHelper.getUniqueValues`, then returns a map object.
- **`makeResponse(data, extraInfo)`** — formats the final response shape; may use a response DTO with `plainToInstance`.

```ts
// ✅ correct structure
async handle(request: StockGetListRequestDto): Promise<any> {
  const { data, count } = await this.stockRepository.getList(request);
  if (isEmpty(data)) return new ResponseBuilder({ data: [], count: 0 }).withCode(ResponseCodeEnum.SUCCESS).build();
  const extraInfo = await this.getExtraInfo(data);
  return new ResponseBuilder({ data: this.makeResponse(data, extraInfo), count }).withCode(ResponseCodeEnum.SUCCESS).build();
}

private async getExtraInfo(data: any[]): Promise<any> {
  const { itemId: itemIds, warehouseId: warehouseIds } = ArrayHelper.getUniqueValues(data, ['itemId', 'warehouseId']);
  const [items, warehouses] = await Promise.all([
    this.itemService.getByCondition({ ids: itemIds } as any),
    this.warehouseService.warehouseGetByCondition({ ids: warehouseIds } as any),
  ]);
  return { itemMap: keyBy(items, 'id'), warehouseMap: keyBy(warehouses, 'id') };
}

private makeResponse(data: any[], extraInfo: any): any[] {
  return data.map((row) => ({
    ...row,
    item: extraInfo.itemMap[row.itemId] ?? null,
    warehouse: extraInfo.warehouseMap[row.warehouseId] ?? null,
  }));
}
```

### 7. Service classes must implement IBaseService

Every service class must implement `IBaseService<TContext, TResult>`. No service class should be left without this contract.

```ts
// ✅ correct
export class StockPutAwayService
  implements IBaseService<StockUpsertSagaContext, void>
{
  async handle(context: StockUpsertSagaContext): Promise<void> {}
}

// ❌ wrong
export class StockPutAwayService {
  async handle(context: StockUpsertSagaContext): Promise<void> {}
}
```

### 8. All numeric calculations must use BigHelper

Never use raw arithmetic operators (`+`, `-`, `*`, `/`) for quantity or numeric business values. Always use `BigHelper` methods to avoid floating-point precision errors.

```ts
// ✅ correct
import { BigHelper } from '@helper/big-decimal.helper';
stock.quantity = BigHelper.subtract(stock.quantity, stock.availableQuantity);
const total = BigHelper.add(a, b);
const result = BigHelper.multiply(price, qty);

// ❌ wrong
stock.quantity = stock.quantity - stock.availableQuantity;
const total = a + b;
```

### 6. No length-guard before NATS service calls

Do not check array length before calling NATS microservices. Call them directly — the service handles empty input internally.

```ts
// ✅ correct
const [items, warehouses] = await Promise.all([
  this.itemService.getByCondition({ ids: itemIds } as any),
  this.warehouseService.warehouseGetByCondition({ ids: warehouseIds } as any),
]);

// ❌ wrong
const [items, warehouses] = await Promise.all([
  itemIds.length ? this.itemService.getByCondition({ ids: itemIds } as any) : [],
  warehouseIds.length ? this.warehouseService.warehouseGetByCondition({ ids: warehouseIds } as any) : [],
]);
```

### 10. File names follow module-name.function.type pattern

File names must follow the pattern `module-name.function.type.ts` where `type` is one of: `service`, `module`, `repository`, `request`, `response`.

```
// ✅ correct
stock.get-list.service.ts
stock.upsert.service.ts
stock-allocation.suggestion.query.ts
item-stock.get-list.request.ts
item-stock.get-list.response.ts
stock.repository.ts
stock.module.ts

// ❌ wrong
stockGetList.service.ts
getListStock.ts
StockService.ts
```

### 9. Use clear, descriptive variable names — no vague suffixes

Avoid vague suffixes like `Delta`, `Payload`, `Data`, `Info`, `Stuff`, `Obj`. Name variables after what they represent.

```ts
// ✅ correct
const stockUpdate = { id: stock.id, keepQuantity: allocated, ... };
const allocationEntity = repository.createEntity({ ... });

// ❌ wrong
const stockDelta = { id: stock.id, keepQuantity: allocated, ... };
const stockData = { ... };
const stockObj = { ... };
```

### 11. Comments only for non-obvious WHY

Do not comment what the code already says; comment a step only when the reason is not visible from the code (a constraint, an ordering requirement, a workaround). This follows the global rule in `~/.claude/CLAUDE.md`.

## Checklist

When applying conventions, verify:

- [ ] DTO extends `PaginationQuery` (not `BaseDto`)
- [ ] `ArrayHelper.getUniqueValues()` used for all ID extraction from arrays
- [ ] All `handle()` and public service method params are explicitly typed
- [ ] Repository query logic is in `query/` files, repository methods are single-line delegates
- [ ] Get-list service follows `handle` → `getExtraInfo` → `makeResponse` structure
- [ ] No length-guard (`arr.length ? ... : []`) before NATS microservice calls
- [ ] Service classes implement `IBaseService<TContext, TResult>`
- [ ] All numeric calculations use `BigHelper` (no raw `+`, `-`, `*`, `/` on quantities)
- [ ] Variable names are descriptive — no vague suffixes like `Delta`, `Data`, `Obj`, `Info`
- [ ] File names follow `module-name.function.type.ts` pattern (kebab-case, dot-separated segments)
- [ ] Each logical step inside multi-step functions has a short comment describing intent
