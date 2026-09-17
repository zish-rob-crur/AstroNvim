return require("user.agent_terminal").new {
  name = "Claude",
  command = function() return { "claude" } end,
  prefill_delay_ms = 1500,
  bracketed_paste = true,
}
