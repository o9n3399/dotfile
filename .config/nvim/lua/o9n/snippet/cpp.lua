local status, ls = pcall(require, "luasnip")
if not status then
  return
end
local snip = ls.parser.parse_snippet

ls.add_snippets("cpp", {
  snip("db", 'cout << "${s2} ::" << ${s2} << endl;'),
})
