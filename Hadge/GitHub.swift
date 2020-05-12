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
    static let didSignIn = Notification.Name("didSignIn")
    static let didSignOut = Notification.Name("didSignOut")
    static let didSetUpRepository = Notification.Name("didSetUpRepository")
}

class GitHub {
    static let sharedInstance = GitHub()

    #if targetEnvironment(simulator)
        static let defaultRepository = "health.debug"
    #else
        static let defaultRepository = "health"
    #endif

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

    func signIn() {
        UIApplication.shared.open(configURL!, options: [:], completionHandler: nil)
    }

    func signOut() {
        self.keychain!["username"] = nil
        self.keychain!["token"] = nil
        self.prepare()
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
                NotificationCenter.default.post(name: .didSignIn, object: nil)
            case .failure(let error):
                os_log("Error while loading user: %@", type: .debug, error.localizedDescription)
            }
        }
    }

    func getRepository(completionHandler: @escaping (String?) -> Swift.Void) {
        Octokit(self.config!).repository(owner: username()!, name: GitHub.defaultRepository) { response in
            switch response {
            case .success(let repository):
                os_log("Repository ID: %d", type: .debug, repository.id)
                completionHandler("\(repository.id)")
            case .failure:
                self.createRepository(completionHandler: completionHandler)
            }
        }
    }

    func createRepository(completionHandler: @escaping (String?) -> Swift.Void) {
        let url = URL(string: "https://api.github.com/user/repos")!
        var request = self.createRequest(url: url, httpMethod: "POST")
        let parameters: [String: Any] = [
            "name": GitHub.defaultRepository,
            "private": true,
            "auto_init": true
        ]
        do {
            request.httpBody = try JSON(parameters).rawData()

            self.handleRequest(request, completionHandler: { json, _, _ in
                completionHandler(json?["id"].stringValue)
            })
        } catch {
        }
    }

    func getFile(path: String, completionHandler: @escaping (String) -> Swift.Void) {
        let url = URL(string: "https://api.github.com/repos/\(username()!)/\(GitHub.defaultRepository)/contents/\(path)")!
        let request = self.createRequest(url: url, httpMethod: "GET")

        self.handleRequest(request, completionHandler: { json, _, _ in
            let sha = json?["sha"].stringValue
            os_log("File sha: %@", type: .debug, sha!)

            if sha != nil {
                completionHandler(sha!)
            }
        })
    }

    func updateFile(path: String, content: String, message: String, completionHandler: @escaping (String?) -> Swift.Void) {
        getFile(path: path) { sha in
            let url = URL(string: "https://api.github.com/repos/\(self.username()!)/\(GitHub.defaultRepository)/contents/\(path)")!
            var request = self.createRequest(url: url, httpMethod: "PUT")
            let parameters: [String: Any] = [
                "message": message,
                "sha": sha,
                "content": content.data(using: String.Encoding.utf8)!.base64EncodedString(),
                "author": [
                    "name": "Hadge",
                    "email": "hadge@entire.io"
                ]
            ]
            do {
                request.httpBody = try JSON(parameters).rawData()

                self.handleRequest(request, completionHandler: { json, _, _ in
                    let sha = json?["content"]["sha"].string
                    os_log("File updated: %@", type: .debug, sha!)

                    completionHandler(sha)
                })
            } catch {
            }
        }
    }

    func createRequest(url: URL, httpMethod: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let loginData = String(format: "%@:%@", username()!, accessToken()!).data(using: String.Encoding.utf8)!
        let base64LoginData = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")

        return request
    }

    func handleRequest(_ request: URLRequest, completionHandler: @escaping (JSON?, Int, Error?) -> Swift.Void) {
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration)
        let task: URLSessionDataTask = session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completionHandler(nil, 0, error)
                return
            }

            if let httpStatus = response as? HTTPURLResponse {
                do {
                    let json = try JSON(data: data)
                    completionHandler(json, httpStatus.statusCode, error)
                } catch {
                    completionHandler(nil, 0, error)
                    return
                }
            }
        }
        task.resume()
    }
}
