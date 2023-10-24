# LÖVEstory
## _Story manager for your game_
LÖVEstory is a parser, command-handler and text-typer for help you make story telling faster in your game.

### Core Feature:
- Text parsing with built-in lexer.
- Easy to register new command and remove existing command.
- Add multiple text file for you story
- Simple to extend.

### Hello World:
```lua
local ls = require "lovestory"

function love.load()
    ls.command.run("'Hello, World!'")
end
function love.update(dt)
    ls.update(dt)
end
function love.draw()
    love.graphics.print(ls.typing.text, 10, 10)
end
```

### DOCUMENTATION SOON
