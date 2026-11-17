# Installing the Beacon widget (~2 minutes in Xcode)

The app already publishes widget data. To show it on the home screen:

1. **Add the widget target**
   File → New → Target… → **Widget Extension** → name it `BeaconWidget`.
   Uncheck "Include Configuration App Intent". Click Finish, and
   **Activate** the scheme when asked.

2. **Replace the template code**
   Delete the generated Swift files in the new `BeaconWidget` folder and
   drag `BeaconWidget.swift` (from this folder) in — make sure its Target
   Membership is the `BeaconWidget` extension, not the app.

3. **Add the shared App Group to BOTH targets**
   For the `Beacon` target AND the `BeaconWidget` target:
   Signing & Capabilities → **+ Capability** → **App Groups** → add
   `group.beacon.shared` (exact spelling — the app writes to this name).

4. Run the app once (it writes the summary), then add the widget from the
   home screen like any other.
