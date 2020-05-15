//
//  CustomViewController.swift
//  Hadge
//
//  Created by Thomas Dohmke on 5/15/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit

class EntireViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setInterfaceStyle()
    }
}

class EntireNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setInterfaceStyle()
    }
}

class EntirePageViewController: UIPageViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setInterfaceStyle()
    }
}

class EntireTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setInterfaceStyle()
    }
}

extension UIViewController {
    func setInterfaceStyle() {
        let value = UserDefaults.standard.integer(forKey: UserDefaultKeys.interfaceStyle)
        let interfaceStyle = InterfaceStyle.init(rawValue: value)
        switch interfaceStyle {
        case .dark:
            overrideUserInterfaceStyle = .dark
        case .light:
            overrideUserInterfaceStyle = .dark
        default:
            overrideUserInterfaceStyle = .unspecified
        }
    }
}
