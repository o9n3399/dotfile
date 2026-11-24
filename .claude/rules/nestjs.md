---
paths:
  - "**/*.service.ts"
  - "**/*.controller.ts"
  - "**/*.repository.ts"
  - "**/*.dto.ts"
  - "**/*.query.ts"
  - "**/*.module.ts"
---

# NestJS (bchh / icd / tst repos)

Load the `nestjs-convention` skill before writing or reviewing code here; it has the examples. The non-negotiables:

- Get-list DTOs extend `PaginationQuery`, not `BaseDto`
- Unique IDs from arrays via `ArrayHelper.getUniqueValues()`
- Quantity math via `BigHelper`, never raw `+ - * /`
- Services implement `IBaseService<TContext, TResult>`; get-list follows `handle` → `getExtraInfo` → `makeResponse`
- Repository query logic lives in `query/` files; repository methods are one-line delegates
- No length guard before NATS calls
- File names: `module-name.function.type.ts`
