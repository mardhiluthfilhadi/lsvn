-- cargo v0.1.1
-- https://github.com/bjornbytes/cargo
-- MIT License

local cargo = {}

local function merge(target, source, ...)
  if not target or not source then return target end
  for k, v in pairs(source) do target[k] = v end
  return merge(target, ...)
end

local la, lf, lg, ls, li = love.audio, love.filesystem, love.graphics, love.sound, love.image

local function makeSound(path)
  local info = lf.getInfo(path, 'file')
  return ls.newSoundData(path)
end

local function makeFont(path)
  return function(size)
    return lg.newFont(path, size)
  end
end

local function runFile(name)
	local ok, chunk, err = pcall(love.filesystem.load, name) -- load the chunk safely
	if not ok    then  return false, "\n\n"..chunk  end
	if not chunk then  return false, "\n\n"..err    end
	local ok, value = pcall(chunk) -- execute the chunk safely
	if not ok then  return false, "\n\n"..tostring(value)  end
	return true, value -- success!
end

local function loadFile(path)
  local ok, content = runFile(path)
  assert(ok, content)
  return content
end

cargo.loaders = {
  lua = lf and loadFile,
  png = lg and lg.newImage,
  jpg = lg and lg.newImage,
  dds = lg and lg.newImage,
  ogv = lg and lg.newVideo,
  glsl = lg and lg.newShader,
  mp3 = la and makeSound,
  ogg = la and makeSound,
  wav = la and makeSound,
  flac = la and makeSound,
  txt = lf and lf.read,
  ttf = lg and makeFont,
  otf = lg and makeFont,
  fnt = lg and lg.newFont
}

cargo.processors = {}

function cargo.init(config)
  if type(config) == 'string' then
    config = { dir = config }
  end

  local loaders = merge({}, cargo.loaders, config.loaders)
  local processors = merge({}, cargo.processors, config.processors)

  local init

  local function halp(t, k)
    local path = (t._path .. '/' .. k):gsub('^/+', '')
    local fileInfo = lf.getInfo(path, 'directory')
    if fileInfo then
      rawset(t, k, init(path))
      return t[k]
    else
      for extension, loader in pairs(loaders) do
        local file = path .. '.' .. extension
        local fileInfo = lf.getInfo(file)
        if loader and fileInfo then
          local asset = loader(file)
          rawset(t, k, asset)
          for pattern, processor in pairs(processors) do
            if file:match(pattern) then
              processor(asset, file, t)
            end
          end
          return asset
        end
      end
    end

    return rawget(t, k)
  end

  local function __call(t, recurse)
    for i, f in ipairs(love.filesystem.getDirectoryItems(t._path)) do
      local key = f:gsub('%..-$', '')
      halp(t, key)

      if recurse and love.filesystem.getInfo(t._path .. '/' .. f, 'directory') then
        t[key](recurse)
      end
    end

    return t
  end

  init = function(path)
    return setmetatable({ _path = path }, { __index = halp, __call = __call })
  end

  return init(config.dir)
end

return cargo
