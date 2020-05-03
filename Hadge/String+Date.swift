//
//  String+Date.swift
//  Hadge
//
//  Created by Thomas Dohmke on 5/2/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import Foundation

extension String {
    func toDate(withFormat format: String = "yyyy-MM-dd HH:mm:ss xxx") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar.current
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)

        return date
    }
}
