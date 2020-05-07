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

        for subView in self.view.subviews where subView is UITextView {
            guard let textView = subView as? UITextView else { continue }
            textView.textContainerInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        }
    }

    @IBAction func signIn(_ sender: Any) {
        if GitHub.shared().isSignedIn() {
            NotificationCenter.default.post(name: .didSignIn, object: nil)
        } else {
            GitHub.shared().signIn()
        }
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

        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        alertController.preferredAction = saveAction

        self.present(alertController, animated: true, completion: nil)
    }
}
