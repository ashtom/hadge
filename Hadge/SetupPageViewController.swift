//
//  SetupPageViewController.swift
//  Hadge
//
//  Created by Thomas Dohmke on 5/5/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit

class SetupPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    lazy var orderedViewControllers = [
        self.viewControllerForIdentifier("HealthRequestViewController"),
        self.viewControllerForIdentifier("LoginViewController")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = self
        self.delegate = self

        let appearance = UIPageControl.appearance(whenContainedInInstancesOf: [UIPageViewController.self])
        appearance.pageIndicatorTintColor = UIColor.secondaryLabel
        appearance.currentPageIndicatorTintColor = UIColor.label

        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else { return nil }

        let previousIndex = viewControllerIndex - 1

        guard previousIndex >= 0 else { return nil }
        guard orderedViewControllers.count > previousIndex else { return nil }

        return orderedViewControllers[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else { return nil }

        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count

        guard orderedViewControllersCount != nextIndex else { return nil }
        guard orderedViewControllersCount > nextIndex else { return nil }

        return orderedViewControllers[nextIndex]
    }

    func viewControllerForIdentifier(_ identifier: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier)
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = viewControllers?.first,
              let firstViewControllerIndex = orderedViewControllers.firstIndex(of: firstViewController) else {
                return 0
        }

        return firstViewControllerIndex
    }
}
