# Wenchy iOS

## Getting Started

1. Install [Carthage](https://github.com/Carthage/Carthage) (Depends on [Homebrew](https://brew.sh)).

    ```
      $ brew update
      $ brew install carthage
    ```

2. Install app dependencies using Carthage.

    ```
      $ carthage bootstrap
    ```

3. Download `GoogleService-Info.plist` corresponding to your project from [Firebase Console](https://console.firebase.google.com) and put it under the `Wenchy` directory (alongside `Info.plist`).

4. Make a copy of `_Wenchy.xcconfig` into `Wenchy.xcconfig`, and update its contents accordingly.
