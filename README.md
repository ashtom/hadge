# Hadge - Health.app Data Git Exporter (for iOS)

[![Build App](https://github.com/ashtom/hadge/actions/workflows/build_app.yml/badge.svg)](https://github.com/ashtom/hadge/actions/workflows/build_app.yml)
[![TestFlight](https://shields.io/static/v1?label=TestFlight&message=Join%20Beta&color=blue)](https://testflight.apple.com/join/rFLkfNSu)

This app serves one simple purpose: Exporting workout data from the Health.app on iOS to a git repo on GitHub. 

At the first launch of the app, you can connect your GitHub account, then the app checks whether a repo with the name `health` exists and, if not, it automatically creates it as a private repo. The initial export dumps all workouts, distances, and daily activity data (the rings on Apple Watch) to .csv files, one per year. The app also registers a background task that gets activated whenever you finish a new workout and then updates the .csv files. 

## TestFlight Beta

You can join the TestFlight Beta [here](https://testflight.apple.com/join/rFLkfNSu). Note that you need to open the link on your iPhone, otherwise TestFlight will show `This beta isn't accepting any new testers right now.` 🙄

## GitHub Actions Workflow

Once you have set up the app (and done some workouts), you can use an Actions workflow to generate workout stats on your GitHub profile. Here's the one from [mine](https://github.com/ashtom):

<img width="445" alt="CleanShot 2021-11-06 at 16 01 29@2x" src="https://user-images.githubusercontent.com/70720/140626256-b84c9945-898e-4570-bbdb-deab1ec3ef18.png">

Steps:

1. Create the file `.github/scripts/hadge.rb` with this [Ruby script](https://gist.github.com/ashtom/1cd9602b122082827b38eb79d605ca1a).
2. Adjust the `DISPLAYED_ACTIVITIES` near the top of the script to match your top workouts. More than 5 won't fit into a pinned gist.
3. Create the file `.github/workflows/hadge.yml` with this [workflow](https://gist.github.com/ashtom/0ca3193ce0ac76f9c6bf0b3aa9cad124).
4. Enable Actions on your repo.
5. Create a new public GitHub Gist [here](https://gist.github.com/).
6. Create a personal access token with the gist scope [here](https://github.com/settings/tokens/new). Copy it.
7. Go yo your repo settings, tab `Secrets`.
8. Create a secret `GH_TOKEN` with the personal access token copied in step 6.
9. Create a secret `GIST_ID` with the ID of the gist from step 5. The ID is the last part of the gist's URL.
10. Trigger an Actions run, either by finished a workout 🙃 or by tapping on a workout in the app, then on the ⊕ icon in the bottom-right corner.

Find other awesome pinned gists in matchai's [awesome-pinned-gists repo](https://github.com/matchai/awesome-pinned-gists).

#### Building

Hadge relies on [swiftlint](https://realm.github.io/SwiftLint/) and 
[sourcery](https://github.com/krzysztofzablocki/Sourcery). They can be installed 
via [homebrew](https://brew.sh) via the provided `Brewfile` by running `brew bundle`
or manually.

Hadge requires a GitHub OAuth application. You will need to create an [OAuth App](https://docs.github.com/en/developers/apps/building-oauth-apps) 
to test and build a version of the application. Once you have your App, you will need to create a `Secrets.xcconfig`
file  locally at the appropriate path that contains the Client ID and Client Secret.

You can locally override the Xcode settings for code signing
by creating a `DeveloperSettings.xcconfig` file locally at the appropriate path.

This allows for a pristine project with theis own OAuth App and code signing set up with the appropriate
developer ID and certificates, and for a developer to be able to have local settings
without needing to check in anything into source control.

You can do this in one of two ways: using the included `setup.sh` script or the files manually.

##### Using `setup.sh`

- Open Terminal and `cd` into the project directory. 
- Run this command to ensure you have execution rights for the script: `chmod +x setup.sh`
- Execute the script with the following command: `./setup.sh` and complete the answers.

##### Manually 

Create a plain text file at the root of the project directory named `DeveloperSettings.xcconfig` and
give it the contents:

```
CODE_SIGN_IDENTITY = Apple Development
DEVELOPMENT_TEAM = <Your Team ID>
CODE_SIGN_STYLE = Automatic
ORGANIZATION_IDENTIFIER = <Your Domain Name Reversed>
```

Set `DEVELOPMENT_TEAM` to your Apple supplied development team.  You can use Keychain
Access to [find your development team ID](/Technotes/FindingYourDevelopmentTeamID.md).
Set `ORGANIZATION_IDENTIFIER` to a reversed domain name that you control or have made up.

Create a plain text file at the root of the project directory named `Hadge/Secrets.xcconfig` and
give it the contents:

```
GITHUB_CLIENT_ID = "<Your GitHub App Client ID>"
GITHUB_CLIENT_SECRET = "<Your GitHub App Client Secrent>"
```

Set `GITHUB_CLIENT_ID` to your GitHub App Client ID and `GITHUB_CLIENT_SECRET` to your 
GitHub App Client Secret.

Now you should be able to build without code signing errors and without modifying
the project

## Privacy Policy

This Privacy Policy describes how your personal information is handled in Hadge for iOS.

We do not collect, use, save, or shared any of your personal data. Hadge exports your workout data to a private GitHub repository in your personal GitHub account. To do this, the app needs access to your Health data. You can choose to disable this at any time in the Health app or by deinstalling Hadge app.

Hadge does not collect any data for any other purposes, and does not send any data to any service other than GitHub. The connection between Hadge and GitHub is directly established through the GitHub API, secured by SSL, and authenticated through your GitHub user. You can delete this connection at any time by revoking the token in your GitHub account settings or by deinstalling Hadge app.

We don’t collect personal information from anyone, including children under the age of 13.

## License

Hadge is published under the MIT License.

Copyright (c) 2020-2021 Thomas Dohmke

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
