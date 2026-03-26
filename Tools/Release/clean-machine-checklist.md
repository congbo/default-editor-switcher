# Clean Machine Checklist

1. Export release credentials and run `./Tools/Release/build-release.sh`.
2. Verify the exported artifact with `./Tools/Release/verify-artifact.sh build/release/exported/DefaultEditorSwitcher.app build/release/DefaultEditorSwitcher-macOS-Universal.zip`.
3. Unzip the final artifact and move `DefaultEditorSwitcher.app` into `/Applications`.
4. Run `./Tools/Release/verify-installed-app.sh /Applications/DefaultEditorSwitcher.app`.
5. Launch the installed app outside Xcode and confirm one successful global editor switch.
6. Trigger or simulate one failure scenario and confirm the menu shows the recovery block plus `Open Settings for Recovery`.
