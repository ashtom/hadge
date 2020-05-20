import UIKit
import AuthenticationServices

class LoginViewController: EntireViewController {
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var tokenButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        signInButton.layer.cornerRadius = 4
        tokenButton.isHidden = !Constants.debug

        for subView in self.view.subviews where subView is UITextView {
            guard let textView = subView as? UITextView else { continue }
            textView.textContainerInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(signInFailed), name: .signInFailed, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .signInFailed, object: nil)
    }

    @IBAction func signIn(_ sender: Any) {
        self.signInButton.isHidden = true

        if GitHub.shared().isSignedIn() {
            NotificationCenter.default.post(name: .didSignIn, object: nil)
        } else {
            self.activityIndicator.startAnimating()
            GitHub.shared().signIn(self)
        }
    }

    @IBAction func enterToken(_ sender: Any) {
        let alertController = UIAlertController(title: "Use a Personal Access Token", message: "This option is only available for debugging purposes and will be removed from the release build.", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { _ -> Void in
            let textField = alertController.textFields![0] as UITextField
            GitHub.shared().storeToken(token: textField.text!)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { _ -> Void in })
        alertController.addTextField { (textField: UITextField!) -> Void in
            textField.isSecureTextEntry = true
            textField.placeholder = "Paste your Token here"
        }

        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        alertController.preferredAction = saveAction

        self.present(alertController, animated: true, completion: nil)
    }

    @objc func signInFailed() {
        DispatchQueue.main.async {
            self.signInButton.isHidden = false
            self.activityIndicator.stopAnimating()
        }
    }
}

extension LoginViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}
