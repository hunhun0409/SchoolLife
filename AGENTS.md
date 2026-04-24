# Repository Guidelines

## Project Structure & Module Organization
The repository root contains a single Godot project in `school-life/`. Treat [`school-life/project.godot`](/C:/Users/hunhun0409/Documents/projects/SchoolLife/school-life/project.godot:1) as the main entrypoint. Commit source assets such as scenes (`*.tscn`), scripts (`*.gd`), and imported asset metadata (`*.import`). Do not commit editor cache under `school-life/.godot/`; it is already ignored. As the game grows, keep runtime content grouped by type, for example `school-life/scenes/`, `school-life/scripts/`, and `school-life/assets/`.

## Build, Test, and Development Commands
Use RTK-wrapped commands when possible.

Run the project locally with `godot --path school-life` or open `school-life/project.godot` in the Godot 4.6 editor. Use `godot --headless --path school-life --quit` for a quick import/config validation in CI or before pushing. There is no separate build system yet; exported builds should be created through Godot export presets once they are added.

## Coding Style & Naming Conventions
Follow the repository `.editorconfig`: UTF-8 text files only. Use 4-space indentation in GDScript and keep one class per file. Prefer `PascalCase` for scene and script filenames (`StudentSchedule.gd`), `snake_case` for variables and functions, and clear node names in scenes (`MainMenu`, `DialogueBox`). Keep resource paths stable; renaming Godot assets without using the editor can break references.

## Testing Guidelines
Automated tests are not set up yet. Until a framework is introduced, validate changes by opening the project in Godot and smoke-testing the affected scene or flow. If you add tests later, place them under `school-life/tests/` and mirror the feature name in the test file, such as `tests/test_dialogue_flow.gd`.

## Commit & Pull Request Guidelines
Current history uses short, imperative commit subjects (`Initial commit`). Keep that pattern: `Add title screen scene`, `Fix dialogue input lock`. Keep commits focused on one change. Pull requests should describe gameplay impact, list edited scenes/scripts, and include screenshots or short clips for visible UI or scene changes. Link related issues when available and note any required Godot version or export preset changes.

## Configuration Tips
The project targets Godot `4.6` with the mobile renderer and Jolt Physics configured in `project.godot`. Preserve those defaults unless the change is intentional and documented in the PR.
