# Gearset Comparison Blueprint

Use this folder as the design branch for a Gearset implementation.

Map the native workflow as follows:

- Azure PR build validation -> Gearset validation-only CI job / PR validation.
- SGD unpackaged delta -> Gearset Delta CI where appropriate.
- Custom metadata comparison -> Gearset comparison + problem analyzers.
- Scratch-org scripting -> Gearset scratch-org CI capabilities where selected.
- Azure deployment evidence -> Gearset deployment history plus external Azure evidence where needed.

Keep unlocked-package ownership decisions explicit. Do not let a comparison tool silently change which delivery mechanism owns a metadata component.
