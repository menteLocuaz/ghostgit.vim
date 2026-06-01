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
    local parts = {}
    for part in string.gmatch(file, "([^%->]+)") do
      table.insert(parts, part:gsub("^%s*(.-)%s*$", "%1"))
    end
    if #parts == 2 then
      result.file = parts[2]
      result.original_file = parts[1]
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
      -- Skip detailed branch info for now or implement if needed
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
