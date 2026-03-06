local status, ls = pcall(require, "luasnip")
if not status then
  return
end
local snip = ls.parser.parse_snippet

ls.add_snippets("markdown", {
  snip(
    "ai-debug",
    [[
## Debug

**Problem:** ${1:describe the bug or unexpected behavior}

**Expected:** ${2:what should happen}

**Actual:** ${3:what actually happens}

**Context:**
```${4:lang}
${5:paste relevant code}
```

**Steps to reproduce:** ${6:steps}
]]
  ),

  snip(
    "ai-task",
    [[
## Task

**Goal:** ${1:what needs to be done}

**Requirements:**
- ${2:requirement 1}
- ${3:requirement 2}

**Constraints:** ${4:any constraints or preferences}

**Context:**
```${5:lang}
${6:relevant code or file}
```
]]
  ),

  snip(
    "ai-refactor",
    [[
## Refactor

**Goal:** ${1:what to improve — readability / performance / structure}

**Code:**
```${2:lang}
${3:paste code to refactor}
```

**Keep in mind:** ${4:things to preserve or avoid changing}
]]
  ),

  snip(
    "ai-review",
    [[
## Code Review

**Review for:** ${1:correctness / security / performance / style}

```${2:lang}
${3:paste code to review}
```

**Focus on:** ${4:specific concerns or areas}
]]
  ),

  snip(
    "ai-explain",
    [[
## Explain

```${1:lang}
${2:paste code}
```

**Explain:** ${3:what aspect to clarify — how it works / why it's written this way / side effects}
]]
  ),

  snip(
    "ai-fix",
    [[
## Fix

**Error:**
```
${1:paste error message or stack trace}
```

**Code:**
```${2:lang}
${3:paste code causing the error}
```

**What I tried:** ${4:previous attempts to fix it}
]]
  ),

  snip(
    "ai-test",
    [[
## Write Tests

**Code to test:**
```${1:lang}
${2:paste function or module}
```

**Test cases to cover:**
- ${3:happy path}
- ${4:edge case}
- ${5:error case}

**Testing framework:** ${6:jest / vitest / pytest / etc}
]]
  ),

  snip(
    "ai-optimize",
    [[
## Optimize

**Goal:** ${1:performance / memory / bundle size / readability}

**Current code:**
```${2:lang}
${3:paste code}
```

**Context:** ${4:how often this runs / data size / bottleneck identified}
]]
  ),

  snip(
    "ai-docs",
    [[
## Write Documentation

```${1:lang}
${2:paste function, class, or module}
```

**Audience:** ${3:other devs / end users / API consumers}

**Include:** ${4:params / return values / examples / edge cases}
]]
  ),

  snip(
    "ai-security",
    [[
## Security Review

```${1:lang}
${2:paste code}
```

**Check for:** ${3:injection / auth issues / data exposure / input validation / etc}

**Context:** ${4:what this code does and who calls it}
]]
  ),

  snip(
    "ai-design",
    [[
## System Design

**Feature:** ${1:what needs to be built}

**Requirements:**
- ${2:functional requirement}
- ${3:non-functional requirement}

**Constraints:** ${4:tech stack / scale / time / team size}

**Questions to answer:** ${5:architecture / data model / API design / trade-offs}
]]
  ),

  snip(
    "ai-migrate",
    [[
## Migration / Upgrade

**From:** ${1:current version, library, or pattern}

**To:** ${2:target version, library, or pattern}

**Current code:**
```${3:lang}
${4:paste code to migrate}
```

**Preserve behavior:** ${5:describe what must not change}
]]
  ),
})
