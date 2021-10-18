import UIKit
import HealthKit

protocol FilterDelegate: AnyObject {
    func onFilterSelected(workoutTypes: [UInt])
}

class FilterViewController: EntireTableViewController {
    var workoutTypes: [HKWorkoutActivityType] = []
    var checked = [Bool]()
    var preChecked = [UInt]()
    var selectAllValue = true
    var selectAllButton: UIButton?

    weak var delegate: FilterDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.workoutTypes = HKWorkoutActivityType.values
        self.workoutTypes.sort { $0.name < $1.name }
        self.checked = [Bool](repeating: false, count: self.workoutTypes.count + 1)
        self.preChecked.forEach { index in
            checked[Int(index)] = true
        }

        let nib = UINib(nibName: "FilterHeaderView", bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: FilterHeaderView.reuseIdentifier)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workoutTypes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "FilterCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell.init(style: .default, reuseIdentifier: identifier)

        cell.selectionStyle = .none
        cell.textLabel?.text = workoutTypes[indexPath.row].name
        let index = Int(workoutTypes[indexPath.row].rawValue)
        if !checked[index] {
            cell.accessoryType = .none
        } else if checked[index] {
            cell.accessoryType = .checkmark
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            let index = Int(workoutTypes[indexPath.row].rawValue)
            if cell.accessoryType == .checkmark {
                 cell.accessoryType = .none
                 checked[index] = false
            } else {
                 cell.accessoryType = .checkmark
                 checked[index] = true
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: FilterHeaderView.reuseIdentifier) as? FilterHeaderView
        guard let selectAllButton = headerView?.viewWithTag(1) as? UIButton else { return nil }
        self.selectAllButton = selectAllButton
        self.selectAllButton?.addTarget(self, action: #selector(selectAllValues(_:)), for: .touchUpInside)
        setSelectAllButtonTitle()
        return headerView!
    }

    @objc func selectAllValues(_ sender: UIButton) {
        self.checked = [Bool](repeating: selectAllValue, count: self.workoutTypes.count + 1)
        setSelectAllButtonTitle()
        selectAllValue = !selectAllValue
        self.tableView.reloadSections([ 0 ], with: .none)
    }

    func setSelectAllButtonTitle() {
        if selectAllValue {
            selectAllButton?.setTitle("Select All", for: .normal)
        } else {
            selectAllButton?.setTitle("Deselect All", for: .normal)
        }
    }

    @IBAction func dismiss(_ sender: Any) {
        var active: [UInt] = []
        self.checked.enumerated().forEach { (index, element) in
            if element {
                active.append(UInt(index))
            }
        }

        if active.count >= self.workoutTypes.count {
            active = []
        }

        self.delegate?.onFilterSelected(workoutTypes: active)
        self.navigationController!.dismiss(animated: true)
    }
}
