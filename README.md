## CodeGPT: writes git commit messages or do a code review brief for you using ChatGPT AI

[![Build Status](https://dev.azure.com/willh/chocolatey-codegpt/_apis/build/status%2Fdoggy8088.chocolatey-codegpt?branchName=master)](https://dev.azure.com/willh/chocolatey-codegpt/_build/latest?definitionId=111&branchName=master)

Project Repo: <https://github.com/appleboy/CodeGPT>

### How to build package

```sh
choco pack
```

### How to test install locally

```sh
choco install codegpt -d -s .
```

### How to test uninstall locally

```sh
choco uninstall codegpt -d -s .
```

### How to publish new version

```sh
choco push codegpt.X.Y.Z.nupkg --source https://push.chocolatey.org/
```

### How to update this package

1. Edit `tools/chocolateyinstall.ps1`

    * `$url64`
    * `checksum64`

2. Edit `codegpt.nuspec`

    * Update `<version>`
    * Update `<releaseNotes>` (reference from [here](https://raw.githubusercontent.com/go-gitea/gitea/master/CHANGELOG.md))

3. Test install

    Open Command Prompt with Administrative right

    ```sh
    choco pack
    choco install codegpt -d -s . -y
    choco uninstall codegpt -d -s .
    ```

4. Publish to Chocolatey Gallery

    ```sh
    choco push codegpt.X.Y.Z.nupkg --source https://push.chocolatey.org/
    ```

### How to build latest version of codegpt chocolatey package

```sh
.\build.ps1
```

This will generate a `publish.ps1` file to help publish to the Chocolatey Gallery.
