import UIKit

class ExpenseCell: UITableViewCell {
    override init(style _: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier) // Subtitle gives you two lines of text
        accessoryType = .disclosureIndicator
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
