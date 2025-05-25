-- A Neovim plugin for displaying both relative and absolute line numbers
-- side by side using the statuscolumn feature (requires Neovim 0.9+)

local M = {}

-- Default configuration
M.config = {
  -- Show mode can be: "relative", "absolute", "both", or "none"
  mode = "both",
  -- Format for numbers: "abs_rel" or "rel_abs"
  format = "abs_rel",
  -- Seperator end of line numbers
  separator = " ",
  -- Custom highlight for relative numbers
  rel_highlight = { link = "LineNr" },
  -- Custom highlight for absolute numbers
  abs_highlight = { link = "LineNr" },
  -- Custom highlight for current line relative numbers
  current_rel_highlight = { link = "CursorLineNr" },
  -- Custom highlight for current line absolute numbers
  current_abs_highlight = { link = "CursorLineNr" },
}

-- Function to get the required width for a number
local function get_width(num)
  return math.max(1, math.floor(math.log(num, 10)) + 1)
end

-- Internal toggle to keep vim.v.relnum up-to-date
local function apply_number_settings()
  vim.opt.number = false
  if M.config.mode == "relative" or M.config.mode == "both" then
    vim.opt.relativenumber = true
  else
    vim.opt.relativenumber = false
  end
end

-- Function to create statuscolumn formatter
local function create_statuscolumn_formatter()
  _G.line_numbers_format = function()
    local ft = vim.bo.filetype
    local bt = vim.bo.buftype

    -- Skip for special buffers
    if ft == "alpha" or ft == "dashboard" or bt == "nofile" or bt == "terminal" or M.config.mode == "none" then
      return ""
    end

    local lnum = vim.v.lnum
    local rnum = math.abs(vim.v.relnum or 0)
    local total = vim.api.nvim_buf_line_count(0)
    local is_current_line = vim.v.relnum == 0

    local abs_w = get_width(total)
    local rel_w = get_width(math.max(1, total - 1))
    local sep = M.config.separator
    local mode = M.config.mode
    local format = M.config.format

    local abs_hl = is_current_line and "LineAbsCurrent" or "LineAbs"
    local rel_hl = is_current_line and "LineRelCurrent" or "LineRel"

    if mode == "both" then
      if format == "abs_rel" then
        return string.format("%%#" .. abs_hl .. "#%" .. abs_w .. "d %%#" .. rel_hl .. "#%" .. rel_w .. "d%s", lnum, rnum, sep)
      else
        return string.format("%%#" .. rel_hl .. "#%" .. rel_w .. "d %%#" .. abs_hl .. "#%" .. abs_w .. "d%s", rnum, lnum, sep)
      end
    elseif mode == "relative" then
      return string.format("%%#" .. rel_hl .. "#%" .. rel_w .. "d%s", rnum, sep)
    else
      return string.format("%%#" .. abs_hl .. "#%" .. abs_w .. "d%s", lnum, sep)
    end
  end

  vim.opt.statuscolumn = "%s%{%v:lua.line_numbers_format()%}"
end

-- Function to change display mode on the fly
function M.set_mode(mode)
  if mode ~= "relative" and mode ~= "absolute" and mode ~= "both" and mode ~= "none" then
    return
  end

  M.config.mode = mode
  apply_number_settings()
  create_statuscolumn_formatter()
end

-- Function to toggle between modes
function M.toggle_mode()
  local modes = { "both", "relative", "absolute", "none" }
  local current_index = 1

  for i, mode in ipairs(modes) do
    if mode == M.config.mode then
      current_index = i
      break
    end
  end

  local next_index = current_index % #modes + 1
  M.set_mode(modes[next_index])
end

-- Setup function to initialize the plugin with user configuration
function M.setup(opts)
  -- Merge user config with defaults
  if opts then
    for k, v in pairs(opts) do
      M.config[k] = v
    end
  end

  -- Setup highlight groups
  vim.api.nvim_set_hl(0, "LineRel", M.config.rel_highlight or { link = "LineNr" })
  vim.api.nvim_set_hl(0, "LineAbs", M.config.abs_highlight or { link = "LineNr" })
  vim.api.nvim_set_hl(0, "LineRelCurrent", M.config.current_rel_highlight or { link = "CursorLineNr" })
  vim.api.nvim_set_hl(0, "LineAbsCurrent", M.config.current_abs_highlight or { link = "CursorLineNr" })

  -- Create autocommands
  local augroup = vim.api.nvim_create_augroup("LineNumbers", { clear = true })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = augroup,
    callback = function()
      vim.api.nvim_set_hl(0, "LineRel", M.config.rel_highlight or { link = "LineNr" })
      vim.api.nvim_set_hl(0, "LineAbs", M.config.abs_highlight or { link = "LineNr" })
      vim.api.nvim_set_hl(0, "LineRelCurrent", M.config.current_rel_highlight or { link = "CursorLineNr" })
      vim.api.nvim_set_hl(0, "LineAbsCurrent", M.config.current_abs_highlight or { link = "CursorLineNr" })
    end,
  })

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "VimResized" }, {
    group = augroup,
    callback = function()
      apply_number_settings()
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "CursorMoved", "CursorMovedI" }, {
    group = augroup,
    callback = function()
      create_statuscolumn_formatter()
    end,
  })

  -- Create the formatter and statuscolumn
  create_statuscolumn_formatter()

  -- Apply number settings
  apply_number_settings()

  -- Create commands
  vim.api.nvim_create_user_command("LineNumberToggle", function()
    M.toggle_mode()
  end, {})

  vim.api.nvim_create_user_command("LineNumberAbsolute", function()
    M.set_mode("absolute")
  end, {})

  vim.api.nvim_create_user_command("LineNumberRelative", function()
    M.set_mode("relative")
  end, {})

  vim.api.nvim_create_user_command("LineNumberBoth", function()
    M.set_mode("both")
  end, {})

  vim.api.nvim_create_user_command("LineNumberNone", function()
    M.set_mode("none")
  end, {})

  -- Set initial mode
  M.set_mode(M.config.mode)
end

return M
