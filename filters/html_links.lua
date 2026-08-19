local pageroot = os.getenv("PAGEROOT") or ""
pageroot = pageroot:gsub("/+$", "")

local function is_absolute(target)
  return target:match("^[%a][%w+.-]*:")
    or target:match("^//")
    or target:match("^/")
    or target:match("^[?#]")
end

local function rewrite_target(target)
  if pageroot == "" or is_absolute(target) then
    return target
  end

  target = target:gsub("^%./", "")
  local stem, suffix = target:match("^(.*)%.md([?#].*)$")
  if stem == nil then
    stem = target:match("^(.*)%.md$")
    suffix = ""
  end
  if stem ~= nil then
    target = stem .. ".html" .. suffix
  end
  return pageroot .. "/" .. target
end

function Link(element)
  element.target = rewrite_target(element.target)
  return element
end

function Image(element)
  element.src = rewrite_target(element.src)
  return element
end
