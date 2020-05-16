import UIKit

class AccountCell: UITableViewCell {
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var loginLabel: UILabel!

    override func awakeFromNib() {
        avatarView.frame = CGRect(x: 0.0, y: 0.0, width: 34.0, height: 34.0)
        avatarView.layer.cornerRadius = 17
        avatarView.clipsToBounds = true
        avatarView.backgroundColor = UIColor.init(red: 27/255, green: 27/255, blue: 27/255, alpha: 1)
    }
}
