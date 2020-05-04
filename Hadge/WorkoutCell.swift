//
//  WorkoutCell.swift
//  Hadge
//
//  Created by Thomas Dohmke on 5/4/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit

class WorkoutCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        emojiLabel.superview?.layer.cornerRadius = 17.0
    }

    func setStartDate(_ date: Date) {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        dateLabel?.text = formatter.localizedString(for: date, relativeTo: Date())
    }

    func setDuration(_ duration: TimeInterval) {
        let time = NSInteger(duration)

        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)

        durationLabel?.text = String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
    }
}
