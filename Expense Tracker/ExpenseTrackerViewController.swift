import UIKit

class ExpenseTrackerViewController: UIViewController, AddExpenseDelegate {

    // 1. Upgrade the TableView style to .insetGrouped
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var expenses: [Expense] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // 2. Use Semantic Colors so Dark/Light mode works perfectly
        view.backgroundColor = .systemGroupedBackground
        title = "Expenses"

        // Make the navigation bar look modern
        navigationController?.navigationBar.prefersLargeTitles = true

        setupTableView()
        setupNavigationBar()
    }

    private func setupNavigationBar() {
        // Changed the button to use a nice '+' icon instead of text
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addExpense))
        navigationItem.rightBarButtonItem = addButton
    }

    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func addExpense() {
        let addVC = AddExpenseViewController()
        addVC.delegate = self
        let navController = UINavigationController(rootViewController: addVC)

        // Make the popup look like a modern sheet
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }

        present(navController, animated: true)
    }
}

// MARK: - TableView Extensions
extension ExpenseTrackerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expenses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let expense = expenses[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = expense.name

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: expense.date)

        // Format the amount to always show two decimal places
        let formattedAmount = String(format: "$%.2f", expense.amount)
        content.secondaryText = "\(formattedAmount) • \(expense.category) • \(dateString)"

        // 3. Add SF Symbol Icons based on the category!
        let iconName: String
        let iconColor: UIColor

        switch expense.category {
        case "Food":
            iconName = "fork.knife"
            iconColor = .systemOrange
        case "Travel":
            iconName = "airplane"
            iconColor = .systemBlue
        case "Miscellaneous":
            iconName = "bag.fill"
            iconColor = .systemPurple
        default:
            iconName = "dollarsign.circle.fill"
            iconColor = .systemGreen
        }

        content.image = UIImage(systemName: iconName)
        content.imageProperties.tintColor = iconColor

        // Make the text look a bit heavier
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.secondaryTextProperties.color = .secondaryLabel

        cell.contentConfiguration = content
        return cell
    }

    func didAddExpense(_ expense: Expense) {
        expenses.append(expense)
        tableView.reloadData()
    }
    // MARK: - Swipe to Delete
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        // 1. Check if the user is trying to delete
        if editingStyle == .delete {

            // 2. Remove the data from your array FIRST
            expenses.remove(at: indexPath.row)

            // 3. Animate the removal of the row from the UI
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
