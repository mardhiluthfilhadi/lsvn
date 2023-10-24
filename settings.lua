local settings = {}

settings.game_author = ""
settings.game_name = "Roooyyy!"
settings.game_version = 0
settings.screen_width = 800
settings.screen_height = 600
settings.screen_resizable = true
settings.slot_for_saving = 20
settings.slot_thumb_width = 40
settings.slot_thumb_height = 40
-- Default game settings
settings.default = {}
-- default fullscreen
settings.default.fullscreen = false
-- default colors
settings.default.background_color = "#000000"

-- default volumes
settings.default.bgm_volume = 1
settings.default.voice_volume = 1
settings.default.sfx_volume = 1
settings.default.video_volume = 1

-- default dialogues
settings.default.stop_voice_when_next_action = false
settings.default.typing_char_per_second_when_normal = 60
settings.default.next_action_wait_when_normal = .7
settings.default.typing_char_per_second_when_skip = 120
settings.default.next_action_wait_when_skip = .2

-- Path for assets folder
-- path for stories
settings.story_folder = "assets.stories"
settings.story_init_file = "init"
settings.story_init_label = "@default"

-- path for images
settings.background_folder = "assets.images.backgrounds"
settings.character_folder = "assets.images.characters"
settings.cg_folder = "assets.images.cgs"

-- path for sounds
settings.voices_folder = "assets.sound.voices"
settings.musics_folder = "assets.sound.musics"
settings.sfx_folder = "assets.sound.sfx"

-- path for videos
settings.video_folder = "assets.video"

-- path for screens
settings.screen_folder = "assets.screens"

return settings
