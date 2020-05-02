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

    var healthStore: HKHealthStore?
    var data: [[String: Any]] = []

    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        healthStore = HKHealthStore()
        loadAvatar()
        setUpRefreshControl()
    }

    override func viewDidAppear(_ animated: Bool) {
        let objectTypes: Set<HKObjectType> = [
            HKObjectType.activitySummaryType(),
            HKObjectType.workoutType()
        ]

        healthStore?.requestAuthorization(toShare: nil, read: objectTypes) { (success, _) in
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
        loadActivityData()
        loadWorkouts()
    }

    func loadActivityData() {
        let calendar = Calendar.autoupdatingCurrent
        var dateComponents = calendar.dateComponents([ .year, .month, .day ], from: Date())
        dateComponents.calendar = calendar

        let predicate = HKQuery.predicateForActivitySummary(with: dateComponents)
        let activityQuery = HKActivitySummaryQuery(predicate: predicate) { (_, summaries, _) in
            guard let summaries = summaries, summaries.count > 0 else { return }
            print(summaries.first?.description ?? "")
        }
        healthStore?.execute(activityQuery)
    }

    func loadWorkouts() {
        let year = Calendar.current.component(.year, from: Date())
        let firstOfYear = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))
        let firstOfNextYear = Calendar.current.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        let lastOfYear = Calendar.current.date(byAdding: .day, value: -1, to: firstOfNextYear!)

        let predicate = HKQuery.predicateForSamples(withStart: firstOfYear, end: lastOfYear, options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let sampleQuery = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: predicate,
            limit: 0,
            sortDescriptors: [sortDescriptor]) { (_, workouts, _) in
                self.data = []

                guard let workouts = workouts, workouts.count > 0 else {
                    self.stopRefreshing()
                    return
                }

                self.createDataFromWorkouts(workouts: workouts)
                if self.freshWorkoutsAvailable(workouts: workouts) {
                    let content = self.generateContentForWorkouts(workouts: workouts)
                    GitHub.shared().updateFile(path: "workouts/2020.csv", content: content, message: "Update workouts from Hadge.app")
                    self.markLastWorkout(workouts: workouts)
                }
                self.stopRefreshing()
        }
        healthStore?.execute(sampleQuery)
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

    func generateContentForWorkouts(workouts: [HKSample]) -> String {
        let header = "uuid,start_date,end_date,type,name,duration,distance,energy\n"
        let content: NSMutableString = NSMutableString.init(string: header)
        workouts.reversed().forEach { workout in
            guard let workout = workout as? HKWorkout else { return }
            let line = "\(workout.uuid),\(workout.startDate),\(workout.endDate),\(workout.workoutActivityType.rawValue),\"\(workout.workoutActivityType.name)\",\(workout.duration),\(workout.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0),\(workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0)\n"
            content.append(line)
        }
        print(content)
        return String.init(content)
    }
}
