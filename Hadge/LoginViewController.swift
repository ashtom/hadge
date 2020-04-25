//
//  LoginViewController.swift
//  Events
//
//  Created by Daniel Adams on 07.02.19.
//  Copyright © 2019 Entire. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet weak var signInButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        signInButton.layer.cornerRadius = 4

        NotificationCenter.default.addObserver(self, selector: #selector(forwardToInitialViewController), name: .didSignInSuccessfully, object: nil)
    }

    @objc func forwardToInitialViewController() {
        DispatchQueue.main.async {
            let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate
            if let rootViewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateInitialViewController() {
                sceneDelegate?.window?.rootViewController = rootViewController
            }
        }
    }

    @IBAction func signIn(_ sender: Any) {
        _ = GitHub.shared().signIn()
    }

    @IBAction func enterToken(_ sender: Any) {
        let alertController = UIAlertController(title: "Use a Personal Access Token", message: "", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { _ -> Void in
            let textField = alertController.textFields![0] as UITextField
            GitHub.shared().storeToken(token: textField.text!)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { _ -> Void in })
        alertController.addTextField { (textField: UITextField!) -> Void in
            textField.placeholder = "Paste your Token here"
        }

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
}
