-- A Neovim plugin for displaying both relative and absolute line numbers
-- side by side using the statuscolumn feature (requires Neovim 0.9+)

local M = {}

-- Default configuration
M.config = {
  -- Initial state of the plugin: true or false
  enabled = true,
  -- Show mode can be: "relative", "absolute", "both", or "none"
  mode = "both",
  -- Format for numbers: "abs_rel" or "rel_abs"
  format = "abs_rel",
  -- Seperator end of line numbers
  separator = " ",
  -- Fallback options for windows where config weren't preserved
  number_fallback = true,
  relativenumber_fallback = true,
  statuscolumn_fallback = "",
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
  if M.config.enabled then
    apply_number_settings()
    create_statuscolumn_formatter()
  end
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

local function create_runtime_autocmds()
  local augroup_runtime = vim.api.nvim_create_augroup("LineNumbersRuntime", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "VimResized" }, {
    group = augroup_runtime,
    callback = function()
      apply_number_settings()
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "CursorMoved", "CursorMovedI" }, {
    group = augroup_runtime,
    callback = function()
      create_statuscolumn_formatter()
    end,
  })
end

function M.toggle_plugin()
  if M.config.enabled then
    M.disable_plugin()
  else
    M.enable_plugin()
  end
end

local last_number_columns_config = {}

local function save_last_number_columns_config()
  last_number_columns_config = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    last_number_columns_config[win] = {
      number = vim.wo[win].number,
      relativenumber = vim.wo[win].relativenumber,
      statuscolumn = vim.wo[win].statuscolumn,
    }
  end
end

function M.enable_plugin()
  if M.config.enabled == true then
    vim.notify("LineNumbers: Already enabled, but enable_plugin() was called", vim.log.levels.WARN)
    return
  end
  M.config.enabled = true
  create_runtime_autocmds()
  save_last_number_columns_config()
  apply_number_settings()
  create_statuscolumn_formatter()
end

function M.disable_plugin()
  if M.config.enabled == false then
    vim.notify("LineNumbers: Already disabled, but disable() was called", vim.log.levels.WARN)
    return
  end
  M.config.enabled = false
  if not pcall(vim.api.nvim_del_augroup_by_name, "LineNumbersRuntime") then
    vim.notify("LineNumbers: Failed to remove autocommands, they may still be active", vim.log.levels.WARN)
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if last_number_columns_config[win] then
      vim.wo[win].number = last_number_columns_config[win].number
      vim.wo[win].relativenumber = last_number_columns_config[win].relativenumber
      vim.wo[win].statuscolumn = last_number_columns_config[win].statuscolumn
    else
      vim.wo[win].number = M.config.number_fallback
      vim.wo[win].relativenumber = M.config.relativenumber_fallback
      vim.wo[win].statuscolumn = M.config.statuscolumn_fallback
    end
  end
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

  -- Create a persistent autocommand once
  local augroup_persistent = vim.api.nvim_create_augroup("LineNumbersPersistent", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = augroup_persistent,
    callback = function()
      vim.api.nvim_set_hl(0, "LineRel", M.config.rel_highlight or { link = "LineNr" })
      vim.api.nvim_set_hl(0, "LineAbs", M.config.abs_highlight or { link = "LineNr" })
      vim.api.nvim_set_hl(0, "LineRelCurrent", M.config.current_rel_highlight or { link = "CursorLineNr" })
      vim.api.nvim_set_hl(0, "LineAbsCurrent", M.config.current_abs_highlight or { link = "CursorLineNr" })
    end,
  })

  save_last_number_columns_config()

  if M.config.enabled then
    -- Create runtime autocommands
    create_runtime_autocmds()
    -- Create the formatter and statuscolumn
    create_statuscolumn_formatter()
    -- Apply number settings
    apply_number_settings()
  end

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

  vim.api.nvim_create_user_command("LineNumberPluginToggle", function()
    M.toggle_plugin()
  end, {})

  vim.api.nvim_create_user_command("LineNumberPluginEnable", function()
    M.enable_plugin()
  end, {})

  vim.api.nvim_create_user_command("LineNumberPluginDisable", function()
    M.disable_plugin()
  end, {})

  -- Set initial mode
  if M.config.enabled then
    M.set_mode(M.config.mode)
  end
end

return M
