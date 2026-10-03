# Roadmap

The monitor's next steps, roughly in order. Small on purpose.

## Next

- **Recordings.** A Record button captures 60 seconds and saves one summary:
  average and peak for each number, stamped with the project's git commit, so
  you can see whether a change made the app heavier. Saved as one plain JSON
  file in SLUJ's Application Support folder, never inside your repos. Orange
  (`#FF9F1A`) is reserved for this.
- **Menu bar icon.** Tinted green / yellow / red while an app is watched, so
  status is visible with the window closed. Needs a slower background check
  (every 5 seconds) to keep the colour right.

## Later

- Editable limits for the status colours.
- More numbers if they earn their place: threads, disk and network activity.
- Then the wider SLUJ direction in the [README](README.md).

## Decided against (for now)

- Quit / Force Quit buttons. SLUJ only watches.
- Always-on recording. Recordings are deliberate, 60 seconds at a time.
