# Super Mario Bros - Safe Spawn Update 🍄


https://github.com/user-attachments/assets/1328f3ca-e713-4829-a48f-234bddd784d8


## Overview
A procedurally generated side-scrolling platformer built in Lua and LÖVE2D, heavily inspired by Super Mario Bros. Features tile map generation, character physics, and basic AI.

## Custom Features
* **Safe Spawn Logic:** Overhauled the level initialization (`PlayState:enter`) to ensure the player never spawns over a bottomless pit. The algorithm scans tiles left-to-right, top-to-bottom, locating the first valid solid ground tile (`TILE_ID_GROUND`) before spawning the player into the world.
