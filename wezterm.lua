local wezterm = require 'wezterm'

wezterm.on('format-tab-title', function(tab)
  local pane_title = tab.active_pane.title or ''
  local user_title = tab.tab_title
  if user_title and #user_title > 0 then
    return ' ' .. user_title .. ': ' .. pane_title .. ' '
  end
  local domain = tab.active_pane.domain_name
  if domain and domain ~= '' and domain ~= 'local' then
    local label = domain:gsub('^SSH:', ''):gsub('^SSHMUX:', '')
    return ' ' .. label .. ': ' .. pane_title .. ' '
  end
  return ' ' .. pane_title .. ' '
end)

local launch_menu = {
  { label = 'PowerShell', args = { 'powershell.exe', '-NoLogo' } },
  { label = 'WSL Ubuntu', args = { 'wsl.exe' } }
}

local function spawn_tab_with_label(window, label, args)
  local mux_win = window:mux_window()
  if not mux_win then return end
  local tab = mux_win:spawn_tab { args = args }
  if tab then
    tab:set_title(label)
  end
end

local function new_tab_picker(window, pane)
  local choices = {}
  for _, item in ipairs(launch_menu) do
    table.insert(choices, { label = item.label })
  end
  window:perform_action(
    wezterm.action.InputSelector {
      title = 'New tab...',
      choices = choices,
      action = wezterm.action_callback(function(win, _, _, label)
        if not label then return end
        for _, item in ipairs(launch_menu) do
          if item.label == label then
            spawn_tab_with_label(win, label, item.args)
            return
          end
        end
      end),
    },
    pane
  )
end

local function spawn_from_launch_menu(index)
  return wezterm.action_callback(function(window)
    local item = launch_menu[index]
    if not item then return end
    spawn_tab_with_label(window, item.label, item.args)
  end)
end

wezterm.on('new-tab-button-click', function(window, pane)
  new_tab_picker(window, pane)
  return false
end)

local function split_with_menu(direction)
  local choices = {}
  for _, item in ipairs(launch_menu) do
    table.insert(choices, { label = item.label })
  end
  return wezterm.action.InputSelector {
    title = 'Split with...',
    choices = choices,
    action = wezterm.action_callback(function(window, pane, _, label)
      if not label then return end
      for _, item in ipairs(launch_menu) do
        if item.label == label then
          local split_args = { direction = direction }
          if item.domain then
            split_args.domain = item.domain
          elseif item.args then
            split_args.command = { args = item.args }
          end
          window:perform_action(wezterm.action.SplitPane(split_args), pane)
          return
        end
      end
    end),
  }
end

return {
  default_prog = { 'powershell.exe', '-NoLogo' },
  launch_menu = launch_menu,

  keys = {
    { key = 'T', mods = 'CTRL|SHIFT', action = wezterm.action_callback(new_tab_picker) },
    { key = 'c', mods = 'ALT', action = wezterm.action.CopyTo 'Clipboard' },
    { key = 'v', mods = 'ALT', action = wezterm.action.PasteFrom 'Clipboard' },
    { key = 'C', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo 'Clipboard' },
    { key = 'V', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom 'Clipboard' },
    { key = 'W', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentPane { confirm = true } },
    { key = 'Tab', mods = 'CTRL', action = wezterm.action.ActivateTabRelative(1) },
    { key = 'Tab', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(-1) },
    { key = 'PageUp', mods = 'CTRL|SHIFT', action = wezterm.action.MoveTabRelative(-1) },
    { key = 'PageDown', mods = 'CTRL|SHIFT', action = wezterm.action.MoveTabRelative(1) },
    { key = 'phys:1', mods = 'CTRL|SHIFT', action = spawn_from_launch_menu(1) },
    { key = 'phys:2', mods = 'CTRL|SHIFT', action = spawn_from_launch_menu(2) },
    { key = 'phys:3', mods = 'CTRL|SHIFT', action = spawn_from_launch_menu(3) },
    { key = 'phys:4', mods = 'CTRL|SHIFT', action = spawn_from_launch_menu(4) },
    { key = 'phys:5', mods = 'CTRL|SHIFT', action = spawn_from_launch_menu(5) },
    { key = 'phys:6', mods = 'CTRL|SHIFT', action = spawn_from_launch_menu(6) },
    { key = 'phys:7', mods = 'CTRL|SHIFT', action = spawn_from_launch_menu(7) },
    { key = 'phys:8', mods = 'CTRL|SHIFT', action = spawn_from_launch_menu(8) },
    { key = 'phys:9', mods = 'CTRL|SHIFT', action = spawn_from_launch_menu(9) },
    { key = 'E', mods = 'CTRL|SHIFT', action = split_with_menu 'Right' },
    { key = 'O', mods = 'CTRL|SHIFT', action = split_with_menu 'Down' },
    { key = 'phys:Comma', mods = 'CTRL', action = wezterm.action_callback(function()
        os.execute('start "" "' .. wezterm.config_file .. '"')
      end) },
    { key = 'R', mods = 'CTRL|SHIFT', action = wezterm.action.PromptInputLine {
        description = 'Rename tab:',
        action = wezterm.action_callback(function(window, _, line)
          if line then window:active_tab():set_title(line) end
        end),
      } },
  },
  mouse_bindings = {
    {
      event = { Down = { streak = 1, button = 'Right' } },
      mods = 'NONE',
      action = wezterm.action_callback(function(window, pane)
        local has_selection = window:get_selection_text_for_pane(pane) ~= ''
        if has_selection then
          window:perform_action(wezterm.action.CopyTo 'Clipboard', pane)
          window:perform_action(wezterm.action.ClearSelection, pane)
        else
          window:perform_action(wezterm.action.PasteFrom 'Clipboard', pane)
        end
      end),
    },
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'NONE',
      action = wezterm.action.CompleteSelection 'ClipboardAndPrimarySelection',
    },
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = wezterm.action.OpenLinkAtMouseCursor,
    },
  },
  font = wezterm.font_with_fallback {
    'Cascadia Code',
    'Malgun Gothic',
  },
  font_size = 11,
}
