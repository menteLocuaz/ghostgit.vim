local M = {}

function M.parse_status_line(line)
  if not line or #line < 3 then
    return {}
  end

  if line:sub(1, 1) == "#" then
    return { type = "unknown", raw = line }
  end

  local index = line:sub(1, 1)
  local worktree = line:sub(2, 2)
  local file = line:sub(4)

  local result = {
    index = index,
    worktree = worktree,
    file = file,
    type = "file_change",
    raw = line
  }

  if index == "R" or index == "C" or worktree == "R" or worktree == "C" then
    local arrow = file:find(" %-> ")
    if arrow then
      local original = file:sub(1, arrow - 1)
      local renamed = file:sub(arrow + 4)
      result.file = renamed
      result.original_file = original
    end
  end

  return result
end

function M.parse_status_output(lines)
  local result = {
    branch = "",
    upstream = "",
    ahead = 0,
    behind = 0,
    items = {}
  }

  if not lines or #lines == 0 then
    return result
  end

  for _, line in ipairs(lines) do
    if line:sub(1, 3) == "## " then
      local branch_info = line:sub(4)

      -- Ahead/Behind
      local ahead = branch_info:match("%[ahead (%d+)")
      local behind = branch_info:match("behind (%d+)%]")
      if not behind then
        behind = branch_info:match("%[behind (%d+)%]")
      end

      result.ahead = tonumber(ahead) or 0
      result.behind = tonumber(behind) or 0

      -- Branch and upstream
      local clean_info = branch_info:gsub("%s%[.*%]$", "")
      local branch, upstream = clean_info:match("([^%.%.%.]+)%.%.%.(.+)")
      if branch then
        result.branch = branch
        result.upstream = upstream
      else
        result.branch = clean_info
      end
    elseif line:sub(1, 1) == "#" then
      -- Parse # branch.head <name>
      local branch_head = line:match("^# branch%.head%s+(.+)$")
      if branch_head then
        result.branch = branch_head
      end
      -- Parse # branch.upstream <name>
      local branch_upstream = line:match("^# branch%.upstream%s+(.+)$")
      if branch_upstream then
        result.upstream = branch_upstream
      end
      -- Parse # branch.ab +<ahead> -<behind>
      local ahead, behind = line:match("^# branch%.ab%s%+(%d+)%s%-+(%d+)$")
      if ahead then
        result.ahead = tonumber(ahead) or 0
        result.behind = tonumber(behind) or 0
      end
    elseif #line > 0 then
      local item = M.parse_status_line(line)
      if item.type == "file_change" then
        table.insert(result.items, item)
      end
    end
  end

  return result
end

return M
