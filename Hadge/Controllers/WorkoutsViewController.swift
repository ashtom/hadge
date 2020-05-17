import UIKit
import HealthKit
import SDWebImage
import SwiftDate

class WorkoutsViewController: EntireViewController {
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
        NotificationCenter.default.addObserver(self, selector: #selector(WorkoutsViewController.didChangeInterfaceStyle), name: .didChangeInterfaceStyle, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(WorkoutsViewController.collectingActivityData), name: .collectingActivityData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(WorkoutsViewController.collectingDistanceData), name: .collectingDistanceData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(WorkoutsViewController.didFinishExport), name: .didFinishExport, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !GitHub.shared().isSignedIn() || !UserDefaults.standard.bool(forKey: UserDefaultKeys.setupFinished) {
            self.navigationController?.performSegue(withIdentifier: "SetupSegue", sender: nil)
        } else {
            GitHub.shared().refreshCurrentUser()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        loadStatusView()

        if UserDefaults.standard.bool(forKey: UserDefaultKeys.setupFinished) {
            loadData(false)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FilterSegue" {
            let filterNavigationViewController = segue.destination as? UINavigationController
            let filterViewController = filterNavigationViewController?.viewControllers.first as? FilterViewController
            filterViewController?.delegate = self
            filterViewController?.preChecked = filter
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
            self.loadData(false)
        }
    }

    @objc func didSignOut() {
        data = []
        tableView.reloadData()
        loadAvatar()

        self.navigationController?.performSegue(withIdentifier: "SetupSegue", sender: nil)
    }

    @objc func didChangeInterfaceStyle() {
        DispatchQueue.main.async {
            self.setInterfaceStyle()
            self.navigationController?.setInterfaceStyle()
        }
    }

    @objc func collectingActivityData() {
        updateStatusLabel("Refreshing activity data...")
    }

    @objc func collectingDistanceData() {
        updateStatusLabel("Refreshing distance data...")
    }

    @objc func didFinishExport() {
        let lastSyncDate = UserDefaults.standard.object(forKey: UserDefaultKeys.lastSyncDate) as? Date
        let formatter = DateFormatter.init()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        if lastSyncDate != nil {
            updateStatusLabel("GitHub last updated on\n\(formatter.string(from: lastSyncDate!)).")
        } else {
            updateStatusLabel("")
        }
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

//                if visible {
//                    let yOffset = self.tableView.contentOffset.y - (self.tableView.refreshControl?.frame.size.height)!
//                    self.tableView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: true)
//                }
            }

            if self.statusLabel != nil {
                self.statusLabel?.text = "Checking for workouts..."
            }
        }
    }

    func updateStatusLabel(_ text: String) {
        DispatchQueue.main.async {
            if self.statusLabel != nil {
                self.statusLabel?.text = text
            }
        }
    }

    func stopRefreshing(_ visible: Bool = true) {
        DispatchQueue.main.async {
            if self.tableView.refreshControl != nil {
//                if visible {
//                    let top = self.tableView.adjustedContentInset.top
//                    let offset = (self.tableView.refreshControl?.frame.maxY)! + top
//                    self.tableView.setContentOffset(CGPoint(x: 0, y: -offset), animated: true)
//                }

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

            guard let workouts = workouts, workouts.count > 0 else { self.stopRefreshing(visible); return }

            self.createDataFromWorkouts(workouts: workouts)
        }
        BackgroundTaskHelper.shared().handleForegroundFetch()
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
            self.stopRefreshing(true)
            self.tableView.reloadSections([ 0 ], with: .automatic)
            self.saveState()
        }
    }
}

extension WorkoutsViewController: UITableViewDataSource {
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
}

extension WorkoutsViewController: UITableViewDelegate {
}

extension WorkoutsViewController: FilterDelegate {
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
}
