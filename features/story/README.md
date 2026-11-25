# story/ (cutscenes + dialog) - not built yet

Owner: the story/visual teammate. Everything story-related lives in this folder so it
never conflicts with battle or upgrade code.

Style notes (from the writing brief): mostly still images with pan/zoom, voice/audio over
them, short text-box dialog during gameplay. Visuals are third person, narration is the
protagonist's knowledge and memories only.

How to hook a scene in without touching battle code:
1. Make `features/story/intro.tscn` (plus `intro.gd`) that plays the cutscene.
2. When it ends, call `GameState.goto(Config.SCENE_BATTLE)` (or `GameState.new_game()`).
3. Add `const SCENE_INTRO := "res://features/story/intro.tscn"` to `core/config.gd`
   and point `title.gd` at it. That is a 2-line change.
