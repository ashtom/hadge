# Hadge - Health.app Data Git Exporter (for iOS)

[![Build App](https://github.com/ashtom/hadge/actions/workflows/build_app.yml/badge.svg)](https://github.com/ashtom/hadge/actions/workflows/build_app.yml)
[![TestFlight](https://shields.io/static/v1?label=TestFlight&message=Join%20Beta&color=blue)](https://testflight.apple.com/join/rFLkfNSu)

This app serves one simple purpose: Exporting workout data from the Health.app on iOS to a git repo on GitHub. 

At the first launch of the app, you can connect your GitHub account, then the app checks whether a repo with the name `health` exists and, if not, it automatically creates it as a private repo. The initial export dumps all workouts, distances, and daily activity data (the rings on Apple Watch) to .csv files, one per year. The app also registers a background task that gets activated whenever you finish a new workout and then updates the .csv files. 

## TestFlight Beta

You can join the TestFlight Beta [here](https://testflight.apple.com/join/rFLkfNSu). Note that you need to open the link on your iPhone, otherwise TestFlight will show `This beta isn't accepting any new testers right now.` 🙄

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
