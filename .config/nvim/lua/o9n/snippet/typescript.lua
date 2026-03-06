local status, ls = pcall(require, "luasnip")
if not status then
  return
end
local snip = ls.parser.parse_snippet

ls.add_snippets("typescript", {
  snip("db", "console.log('<=========>    ',${1})"),
  snip("jlog", "console.log('<=========>    ${1}',JSON.stringify(${1}, null, 2))"),
  snip("tlog", "console.time('<=========>    ${1}') \n  console.timeEnd('<=========>    ${1}')"),
})

ls.add_snippets("javascript", {
  snip("db", "console.log('<=========>    ',${1})"),
})
