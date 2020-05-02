//
//  ViewController.swift
//  Hadge
//
//  Created by Thomas Dohmke on 4/24/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit
import HealthKit
import SDWebImage

class WorkoutsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let userDefaultsLastWorkoutKey = "lastWorkout"

    var data: [[String: Any]] = []

    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        loadAvatar()
        setUpRefreshControl()
    }

    override func viewDidAppear(_ animated: Bool) {
        let objectTypes: Set<HKObjectType> = [
            HKObjectType.activitySummaryType(),
            HKObjectType.workoutType()
        ]

        Health.shared().healthStore?.requestAuthorization(toShare: nil, read: objectTypes) { (success, _) in
            if success {
                self.loadData()
            }
        }

        // Debug stuff, will remove later
        //GitHub.shared().getRepository()
        //GitHub.shared().updateFile(path: "README.md", content: "This repo is automatically updated by Hadge.app", message: "Update from Hadge.app")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "DataCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell.init(style: .subtitle, reuseIdentifier: identifier)

        if let title = data[indexPath.row]["title"] as? String? {
            cell.textLabel?.text = title
        }

        return cell
    }

    @objc func showSettings(sender: Any) {
        performSegue(withIdentifier: "SettingsSegue", sender: self)
    }

    @objc func refreshWasRequested(_ refreshControl: UIRefreshControl) {
        startRefreshing()
        loadData()
    }

    func startRefreshing() {
        DispatchQueue.main.async {
            if self.tableView.refreshControl != nil {
                self.tableView.refreshControl?.beginRefreshing()

                let yOffset = self.tableView.contentOffset.y - (self.tableView.refreshControl?.frame.size.height)!
                self.tableView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: true)
            }
        }
    }

    func stopRefreshing() {
        DispatchQueue.main.async {
            if self.tableView.refreshControl != nil {
                let top = self.tableView.adjustedContentInset.top
                let offset = (self.tableView.refreshControl?.frame.maxY)! + top
                self.tableView.setContentOffset(CGPoint(x: 0, y: -offset), animated: true)

                self.tableView.refreshControl?.endRefreshing()
            }
        }
    }

    func loadAvatar() {
        self.navigationItem.leftBarButtonItem = nil

        let avatarButton = UIButton(type: .custom)
        avatarButton.frame = CGRect(x: 0.0, y: 0.0, width: 34.0, height: 34.0)
        avatarButton.layer.cornerRadius = 17
        avatarButton.clipsToBounds = true
        avatarButton.backgroundColor = UIColor.init(red: 27/255, green: 27/255, blue: 27/255, alpha: 1)
        avatarButton.addTarget(self, action: #selector(showSettings(sender:)), for: .touchUpInside)
        let barButtonItem = UIBarButtonItem(customView: avatarButton)

        let username = GitHub.shared().returnAuthenticatedUsername()
        let avatarURL = "https://github.com/\(username).png?size=102"
        let imageManager = SDWebImageManager.shared
        imageManager.loadImage(with: URL(string: avatarURL),
                               options: [],
                               progress: nil,
                               completed: { image, _, _, _, _, _ in
            avatarButton.setBackgroundImage(image, for: .normal)
        })

        // Setting the constraints is required to prevent the button size from resetting after segue back from details
        barButtonItem.customView?.widthAnchor.constraint(equalToConstant: 34).isActive = true
        barButtonItem.customView?.heightAnchor.constraint(equalToConstant: 34).isActive = true

        self.navigationItem.leftBarButtonItem = barButtonItem
    }

    func setUpRefreshControl() {
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(WorkoutsViewController.refreshWasRequested(_:)), for: UIControl.Event.valueChanged)
    }

    func loadData() {
        startRefreshing()

        Health.shared().loadActivityData()
        Health.shared().loadWorkouts { workouts in
            self.data = []

            guard let workouts = workouts, workouts.count > 0 else {
                self.stopRefreshing()
                return
            }

            self.createDataFromWorkouts(workouts: workouts)
            if self.freshWorkoutsAvailable(workouts: workouts) {
                let content = Health.shared().generateContentForWorkouts(workouts: workouts)
                let filename = "workouts/\(Health.shared().year).csv"
                GitHub.shared().updateFile(path: filename, content: content, message: "Update workouts from Hadge.app")

                self.markLastWorkout(workouts: workouts)
            }
            self.stopRefreshing()
        }
    }

    func freshWorkoutsAvailable(workouts: [HKSample]) -> Bool {
        guard let workout = workouts.first as? HKWorkout else { return false }

        let lastWorkout = UserDefaults.standard.string(forKey: userDefaultsLastWorkoutKey)
        if lastWorkout == nil || lastWorkout != workout.uuid.uuidString {
            return true
        } else {
            return false
        }
    }

    func markLastWorkout(workouts: [HKSample]) {
        guard let workout = workouts.first as? HKWorkout else { return }

        UserDefaults.standard.set(workout.uuid.uuidString, forKey: userDefaultsLastWorkoutKey)
    }

    func createDataFromWorkouts(workouts: [HKSample]) {
        workouts.forEach { workout in
            guard let workout = workout as? HKWorkout else { return }
            data.append([ "title": workout.workoutActivityType.associatedEmojiMale! + " " + workout.workoutActivityType.name ])
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
