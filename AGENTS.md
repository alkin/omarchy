This is a fork of Omarchy, an opinionated Linux distribution by DHH based on the Arch Linux distribution.

In this fork, we will be adding a few customizations to the distribution to make it more suitable for my use case.

All the customizations will be done in the `custom` folder.

We will not change any of the existing files or folders.

The `custom` folder will have a run.sh script that will be used to run the customizations.

Each customization will be a separate file and execute a specific task, like installing a package, changing a configuration file, etc.

Assume:
- All omarchy-* commands are available.
- yay is available.
- Pipewire is the default sound backend.

Scripts should be idempotent. Running them multiple times should not generate duplicates or unexpected consequences.