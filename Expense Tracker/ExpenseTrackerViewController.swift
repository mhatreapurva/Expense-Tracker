import UIKit
import SwiftUI

class ExpenseTrackerViewController: UIViewController, AddExpenseDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var expenses: [Expense] = []
    private let defaults = UserDefaults.standard
    private let saveKey = "savedExpenses"
    
    // Use a single instance of the hosting controller to prevent memory leaks and "ghost" charts
    private var dashboardController: UIHostingController<DashboardView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground
        title = "Expenses"
        navigationController?.navigationBar.prefersLargeTitles = true

        setupTableView()
        setupNavigationBar()
        loadExpenses()
    }

    private func setupNavigationBar() {
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
        
        // Initialize the SwiftUI dashboard once
        let dashboardView = DashboardView(expenses: expenses)
        dashboardController = UIHostingController(rootView: dashboardView)
        dashboardController?.view.backgroundColor = .clear
        
        if let controller = dashboardController {
            addChild(controller)
            controller.didMove(toParent: self)
            
            // Calculate exact height needed by SwiftUI and assign to table header
            let targetSize = controller.view.sizeThatFits(CGSize(width: view.frame.width, height: UIView.layoutFittingExpandedSize.height))
            controller.view.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: targetSize.height)
            tableView.tableHeaderView = controller.view
        }
    }
    
    // Helper function to safely update the data without causing layout crashes
    private func refreshDashboard() {
        dashboardController?.rootView = DashboardView(expenses: expenses)
        
        if let headerView = dashboardController?.view {
            let targetSize = headerView.sizeThatFits(CGSize(width: view.frame.width, height: UIView.layoutFittingExpandedSize.height))
            headerView.frame.size.height = targetSize.height
            tableView.tableHeaderView = headerView
        }
    }

    private func saveExpenses() {
        if let encodedData = try? JSONEncoder().encode(expenses) {
            defaults.set(encodedData, forKey: saveKey)
        }
    }
        
    private func loadExpenses() {
        if let savedData = defaults.data(forKey: saveKey) {
            if let decodedExpenses = try? JSONDecoder().decode([Expense].self, from: savedData) {
                expenses = decodedExpenses
                tableView.reloadData()
                refreshDashboard()
            }
        }
    }

    @objc private func addExpense() {
        let addVC = AddExpenseViewController()
        addVC.delegate = self
        let navController = UINavigationController(rootViewController: addVC)

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

        let formattedAmount = String(format: "$%.2f", expense.amount)
        content.secondaryText = "\(formattedAmount) • \(expense.category) • \(dateString)"

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

        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.secondaryTextProperties.color = .secondaryLabel

        cell.contentConfiguration = content
        return cell
    }

    func didAddExpense(_ expense: Expense) {
        expenses.append(expense)
        tableView.reloadData()
        saveExpenses()
        refreshDashboard()
    }
    
    // MARK: - Swipe to Delete
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            expenses.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            saveExpenses()
            refreshDashboard()
        }
    }
}
