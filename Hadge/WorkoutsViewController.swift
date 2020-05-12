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

class WorkoutsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FilterDelegate {
    var data: [[String: Any]] = []
    var statusLabel: UILabel?
    var filter: [UInt] = []
    var filterButton: UIBarButtonItem?

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        loadAvatar()
        setUpRefreshControl()
        restoreState()

        NotificationCenter.default.addObserver(self, selector: #selector(WorkoutsViewController.didSignIn), name: .didSetUpRepository, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(WorkoutsViewController.didSignOut), name: .didSignOut, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !GitHub.shared().isSignedIn() || !UserDefaults.standard.bool(forKey: UserDefaultKeys.setupFinished) {
            self.navigationController?.performSegue(withIdentifier: "SetupSegue", sender: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        loadStatusView()
        loadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "WorkoutCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? WorkoutCell

        if let workout = data[indexPath.row]["workout"] as? HKWorkout? {
            cell?.titleLabel?.text = workout?.workoutActivityType.name
            cell?.emojiLabel?.text = workout?.workoutActivityType.associatedEmoji(for: Health.shared().getBiologicalSex()!)
            cell?.setStartDate(workout!.startDate)
            cell?.setDistance(workout!.totalDistance)
            cell?.setDuration(workout!.duration)
            cell?.setEnergy(workout!.totalEnergyBurned)
            cell?.sourceLabel?.text = workout!.sourceRevision.source.name
        }

        return cell!
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FilterSegue" {
            let filterNavigationViewController = segue.destination as? UINavigationController
            let filterViewController = filterNavigationViewController?.viewControllers.first as? FilterViewController
            filterViewController?.delegate = self
            filterViewController?.preChecked = filter
        }
    }

    func onFilterSelected(workoutTypes: [UInt]) {
        if !filter.elementsEqual(workoutTypes) {
            filter = workoutTypes
            if filter.isEmpty {
                self.filterButton?.tintColor = UIColor.secondaryLabel
            } else {
                self.filterButton?.tintColor = UIColor.systemBlue
            }
            self.loadData(false)
        }
    }

    @objc func showFilter(sender: Any) {
        performSegue(withIdentifier: "FilterSegue", sender: self)
    }

    @objc func showSettings(sender: Any) {
        performSegue(withIdentifier: "SettingsSegue", sender: self)
    }

    @objc func didSignIn() {
        DispatchQueue.main.async {
            self.loadAvatar()
            self.loadData()
        }
    }

    @objc func didSignOut() {
        data = []
        tableView.reloadData()
        loadAvatar()

        self.navigationController?.performSegue(withIdentifier: "SetupSegue", sender: nil)
    }

    @objc func refreshWasRequested(_ refreshControl: UIRefreshControl) {
        startRefreshing()
        loadData()
    }

    @objc func openSafari(sender: Any) {
        UIApplication.shared.open(URL.init(string: "https://github.com/\(GitHub.shared().username()!)/\(GitHub.defaultRepository)")!)
    }

    func startRefreshing(_ visible: Bool = true) {
        DispatchQueue.main.async {
            if self.tableView.refreshControl != nil {
                self.tableView.refreshControl?.beginRefreshing()

                if visible {
                    let yOffset = self.tableView.contentOffset.y - (self.tableView.refreshControl?.frame.size.height)!
                    self.tableView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: true)
                }
            }

            if self.statusLabel != nil {
                self.statusLabel?.text = "Checking for workouts..."
            }
        }
    }

    func stopRefreshing(_ visible: Bool = true) {
        DispatchQueue.main.async {
            if self.tableView.refreshControl != nil {
                if visible {
                    let top = self.tableView.adjustedContentInset.top
                    let offset = (self.tableView.refreshControl?.frame.maxY)! + top
                    self.tableView.setContentOffset(CGPoint(x: 0, y: -offset), animated: true)
                }

                self.tableView.refreshControl?.endRefreshing()
            }

            if self.statusLabel != nil {
                let lastSyncDate = UserDefaults.standard.object(forKey: UserDefaultKeys.lastSyncDate) as? Date
                let formatter = DateFormatter.init()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                if lastSyncDate != nil {
                    self.statusLabel?.text = "GitHub last updated on\n\(formatter.string(from: lastSyncDate!))."
                } else {
                    self.statusLabel?.text = ""
                }
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

    func loadStatusView() {
        statusLabel = UILabel(frame: CGRect.init(x: 0, y: 0, width: 200, height: 34))
        statusLabel?.text = ""
        statusLabel?.textAlignment = NSTextAlignment.center
        statusLabel?.textColor = UIColor.secondaryLabel
        statusLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        statusLabel?.lineBreakMode = .byWordWrapping
        statusLabel?.numberOfLines = 2

        let statusItem = UIBarButtonItem(customView: statusLabel!)
        filterButton = UIBarButtonItem(image: UIImage(systemName: "line.horizontal.3.decrease.circle"), style: .plain, target: self, action: #selector(showFilter(sender:)))
        filterButton?.tintColor = (self.filter.isEmpty ? UIColor.secondaryLabel : UIColor.systemBlue)
        let rightButtonItem = UIBarButtonItem(image: UIImage(systemName: "safari"), style: .plain, target: self, action: #selector(openSafari(sender:)))
        rightButtonItem.tintColor = UIColor.secondaryLabel
        let leftSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let rightSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.navigationController?.toolbar.setItems([filterButton!, leftSpaceItem, statusItem, rightSpaceItem, rightButtonItem], animated: false)
    }

    func setUpRefreshControl() {
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(WorkoutsViewController.refreshWasRequested(_:)), for: UIControl.Event.valueChanged)
    }

    func restoreState() {
        self.filter = UserDefaults.standard.array(forKey: UserDefaultKeys.workoutFilter) as? [UInt] ?? [UInt]()
    }

    func saveState() {
        UserDefaults.standard.set(self.filter, forKey: UserDefaultKeys.workoutFilter)
        UserDefaults.standard.synchronize()
    }

    func loadData(_ visible: Bool = true) {
        startRefreshing(visible)
        loadWorkouts(visible)
    }

    func loadWorkouts(_ visible: Bool = true) {
        Health.shared().getWorkouts { workouts in
            self.data = []

            guard let workouts = workouts, workouts.count > 0 else {
                self.stopRefreshing(visible)
                return
            }

            self.createDataFromWorkouts(workouts: workouts)
            if self.freshWorkoutsAvailable(workouts: workouts) {
                let content = Health.shared().generateContentForWorkouts(workouts: workouts)
                let filename = "workouts/\(Health.shared().year).csv"
                GitHub.shared().updateFile(path: filename, content: content, message: "Update workouts from Hadge.app") { _ in
                    self.markLastWorkout(workouts: workouts)
                    self.loadActivity(visible)
                }
            } else {
                self.loadActivity(visible)
            }
        }
    }

    func loadActivity(_ visible: Bool = true) {
        Health.shared().getActivityData { summaries in
            let content = Health.shared().generateContentForActivityData(summaries: summaries)
            let filename = "activity/\(Health.shared().year).csv"
            GitHub.shared().updateFile(path: filename, content: content, message: "Update activity from Hadge.app") { _ in
                self.stopRefreshing(visible)
            }
        }

        let now = Date.init()
        Health.shared().getQuantityForDate(HKQuantityType.quantityType(forIdentifier: .stepCount)!, unit: HKUnit.count(), date: now) { sum in print("Steps: \(sum)") }
        Health.shared().getQuantityForDate(HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!, unit: HKUnit.count(), date: now) { sum in print("Flights Climbed: \(sum)") }
        Health.shared().getQuantityForDate(HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!, unit: HKUnit.meter(), date: now) { sum in print("Distance: \(sum)") }

        Health.shared().getQuantityForDates(HKQuantityType.quantityType(forIdentifier: .stepCount)!, unit: HKUnit.count(), start: Health.shared().firstOfYear!, end: Health.shared().lastOfYear!) { statistics in
            if let quantity = statistics?.sumQuantity() {
                let date = statistics?.startDate
                let steps = quantity.doubleValue(for: HKUnit.count())
                print("\(date.debugDescription): steps = \(steps)")
            }
        }
    }

    func freshWorkoutsAvailable(workouts: [HKSample]) -> Bool {
        guard let workout = workouts.first as? HKWorkout else { return false }

        let lastWorkout = UserDefaults.standard.string(forKey: UserDefaultKeys.lastWorkout)
        if lastWorkout == nil || lastWorkout != workout.uuid.uuidString {
            return true
        } else {
            return false
        }
    }

    func markLastWorkout(workouts: [HKSample]) {
        guard let workout = workouts.first as? HKWorkout else { return }

        UserDefaults.standard.set(workout.uuid.uuidString, forKey: UserDefaultKeys.lastWorkout)
        UserDefaults.standard.set(Date.init(), forKey: UserDefaultKeys.lastSyncDate)
    }

    func createDataFromWorkouts(workouts: [HKSample]) {
        workouts.forEach { workout in
            guard let workout = workout as? HKWorkout else { return }
            if filter.isEmpty || filter.firstIndex(of: workout.workoutActivityType.rawValue) != nil {
                data.append([
                    "title": workout.workoutActivityType.name,
                    "workout": workout
                ])
            }
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.saveState()
        }
    }
}
