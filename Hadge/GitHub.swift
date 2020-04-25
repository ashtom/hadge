//
//  GitHub.swift
//  Events
//
//  Created by Thomas Dohmke on 4/1/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit
import KeychainAccess
import OctoKit
import SwiftyJSON
import os.log

extension Notification.Name {
    static let didSignInSuccessfully = Notification.Name("didSignInSuccessfully")
}

class GitHub {
    static let sharedInstance = GitHub()

    var configURL: URL?
    var config: TokenConfiguration?
    var oauth: OAuthConfiguration?
    var keychain: Keychain?
    var lastEventId: Int? = 0

    static func shared() -> GitHub {
        return sharedInstance
    }

    func prepare() {
        keychain = Keychain(service: "io.entire.hadge.github-token")
        if (keychain!["token"] == nil) || (keychain!["token"]?.isEmpty)! {
            oauth = OAuthConfiguration(token: "7a2396d1a9ac75fed9b0", secret: "f87475160cb99b4cbf09566e82865b254f03fd65", scopes: ["repo"])
            configURL = oauth!.authenticate()
        } else {
            config = TokenConfiguration(self.keychain!["token"])
        }
    }

    func isSignedIn() -> Bool {
        return (keychain!["token"] != nil) && !(keychain!["token"]?.isEmpty)! && (self.keychain!["username"] != nil) && !(self.keychain!["username"]?.isEmpty)!
    }

    func returnAuthenticatedUsername() -> String {
        if isSignedIn() {
            return self.keychain!["username"]!
        } else {
            return "github"
        }
    }

    func signIn() -> Bool {
        if !isSignedIn() {
            UIApplication.shared.open(configURL!, options: [:], completionHandler: nil)
            return false
        } else {
            return true
        }
    }

    func signOut() -> Bool {
        self.keychain!["token"] = nil
        self.prepare()
        return true
    }

    func process(url: URL) {
        oauth!.handleOpenURL(url: url) { config in
            self.loadCurrentUser(config: config)
        }
    }

    func storeToken(token: String) {
        self.loadCurrentUser(config: TokenConfiguration(token))
    }

    func accessToken() -> String? {
        self.keychain!["token"]
    }

    func username() -> String? {
        self.keychain!["username"]
    }

    func loadCurrentUser(config: TokenConfiguration) {
        _ = Octokit(config).me { response in
            switch response {
            case .success(let user):
                os_log("GitHub User: %@", type: .debug, user.login!)

                self.keychain!["username"] = user.login
                self.keychain!["token"] = config.accessToken
                os_log("Token stored", type: .debug)

                self.config = TokenConfiguration(self.keychain!["token"])
                NotificationCenter.default.post(name: .didSignInSuccessfully, object: nil)
            case .failure(let error):
                os_log("Error while loading user: %@", type: .debug, error.localizedDescription)
            }
        }
    }
}
