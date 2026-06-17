# Game of Life (Odin)

Conway's Game of Life built with [Odin](https://odin-lang.org/) and [Raylib](https://www.raylib.com/).

## Requirements

- [Odin](https://odin-lang.org/docs/install/) (dev-2026-06 or later)

## Run

```bash
odin run .
```

Run from the project root so `patterns.txt` is found.

## Controls

- **Left click** on the grid — toggle a cell
- **Run / Pause** — start or stop the simulation
- **Pattern buttons** — scroll and select a preset pattern

## Patterns

Presets live in `patterns.txt`. Each line is `name|x,y;x,y;...` where offsets are relative to the click position.
