---@type vim.lsp.Config
return {
  filetypes = { "markdown", "typescriptreact" },
  settings = {
    ["harper-ls"] = {
      linters = {
        SpellCheck = true,
        SpelledNumbers = false,
        AnA = true,
        SentenceCapitalization = true,
        UnclosedQuotes = true,
        WrongQuotes = false,
        LongSentences = true,
        RepeatedWords = true,
        Spaces = true,
        Matcher = true,
        CorrectNumberSuffix = true,
      },
      codeActions = { ForceStable = false },
      markdown = { IgnoreLinkTitle = false },
      diagnosticSeverity = "hint",
      isolateEnglish = false,
      dialect = "American",
    },
  },
}
