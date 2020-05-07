//
//  SetupViewController.swift
//  Hadge
//
//  Created by Thomas Dohmke on 5/6/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit

class SetupViewController: UIViewController {
    override func viewDidLoad() {
        GitHub.shared().getRepository { _ in
            GitHub.shared().updateFile(path: "README.md", content: "This repo is automatically updated by Hadge.app", message: "Update from Hadge.app") { _ in
                UserDefaults.standard.set(true, forKey: UserDefaultKeys.setupFinished)
                NotificationCenter.default.post(name: .didSetUpRepository, object: nil)
            }
        }
    }
}
