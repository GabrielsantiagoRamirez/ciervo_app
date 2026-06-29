# Skill: Experience Mode (Day / Night)

## Context
Ciervo must support two contextual experience modes:
- Day Mode
- Night Mode

This is not only a color change. It affects visual theme, recommended content, categories, and UI mood.

## Task
Implement a global Experience Mode system for the app.

## Requirements
- Create a global ExperienceMode enum:
  - day
  - night

- Create a Cubit to manage the selected mode:
  - ExperienceModeCubit

- The selected mode must affect:
  - app theme
  - category labels
  - featured mock content
  - cards overlays and tone
  - section titles or subtitles where needed

## Theme requirements
- Refactor the current design system to support:
  - CiervoNightTheme
  - CiervoDayTheme

- Do not duplicate screens
- Reuse the same UI structure and widgets
- Use theme tokens and contextual rendering

## UI requirements
- The Home screen must support Day/Night switching visually
- Categories should adapt to mode:
  - Night examples: Bars, Clubs, Events, Liquor
  - Day examples: Cafes, Restaurants, Brunch, Rooftops

- Cards should adapt imagery tone and overlay intensity depending on mode

## Architecture
- Keep clean feature-based architecture
- Keep repository/mock structure intact
- Keep code modular and scalable

## Constraints
- No backend yet
- Use mock data only
- Keep app runnable
- Do not break existing navigation