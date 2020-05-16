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
