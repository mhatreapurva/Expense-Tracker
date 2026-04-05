import UIKit
import SwiftUI

class ExpenseTrackerViewController: UIViewController, AddExpenseDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var expenses: [Expense] = []
    private let defaults = UserDefaults.standard
    private let saveKey = "savedExpenses"
    
    // Date Range State
    private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())! // Default: Last 30 days
    private var endDate: Date = Date()
    
    private var dashboardController: UIHostingController<DashboardView>?

    // The Master Filter: Everything on screen pulls from this array, not the main 'expenses' array
    private var filteredExpenses: [Expense] {
        return expenses.filter { $0.date >= startDate && $0.date <= endDate }
            .sorted(by: { $0.date > $1.date }) // Sort newest to oldest
    }

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
        let filterButton = UIBarButtonItem(image: UIImage(systemName: "calendar.badge.clock"), style: .plain, target: self, action: #selector(presentDateFilter))
        navigationItem.rightBarButtonItems = [addButton]
        
        let seedButton = UIBarButtonItem(title: "Seed", style: .plain, target: self, action: #selector(handleSeedTapped))
        navigationItem.leftBarButtonItems = [filterButton, seedButton]
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
        
        // Pass the FILTERED expenses to the dashboard
        let dashboardView = DashboardView(expenses: filteredExpenses)
        dashboardController = UIHostingController(rootView: dashboardView)
        dashboardController?.view.backgroundColor = .clear
        
        if let controller = dashboardController {
            addChild(controller)
            controller.didMove(toParent: self)
            
            let targetSize = controller.view.sizeThatFits(CGSize(width: view.frame.width, height: UIView.layoutFittingExpandedSize.height))
            controller.view.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: targetSize.height)
            tableView.tableHeaderView = controller.view
        }
    }
    
    private func refreshDashboard() {
        // Update dashboard with the latest FILTERED data
        dashboardController?.rootView = DashboardView(expenses: filteredExpenses)
        
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

    // MARK: - Actions
    @objc private func addExpense() {
        let addVC = AddExpenseViewController()
        addVC.delegate = self
        let navController = UINavigationController(rootViewController: addVC)

        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        present(navController, animated: true)
    }
    
    @objc private func handleSeedTapped() {
        seedData()
    }
    
    @objc private func presentDateFilter() {
            // 1. Create the SwiftUI View, passing in our current dates and a completion handler
            let filterView = DateFilterView(startDate: self.startDate, endDate: self.endDate) { [weak self] newStart, newEnd in
                guard let self = self else { return }
                
                self.startDate = newStart
                // Push end date to the end of the day to ensure we catch all expenses on that day
                self.endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: newEnd) ?? newEnd
                
                self.tableView.reloadData()
                self.refreshDashboard()
            }
            
            // 2. Wrap it in a Hosting Controller
            let hostingController = UIHostingController(rootView: filterView)
            
            // 3. Make it a modern "Half Sheet" that slides up from the bottom
            if let sheet = hostingController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true // Adds the little grey pill at the top
            }
            
            present(hostingController, animated: true)
        }

    // MARK: - Debugging Helpers
    private func seedData() {
        let categories = ["Housing", "Utilities", "Groceries", "Food & Dining", "Travel", "Entertainment", "Shopping", "Health", "Miscellaneous"]
        let names = ["Rent", "Electricity", "Whole Foods", "Dinner Out", "Uber", "Movie Night", "Amazon", "Gym", "Pharmacy"]
        
        var dummyExpenses: [Expense] = []
        
        for _ in 1...20 {
            let randomName = names.randomElement() ?? "Expense"
            let randomAmount = Double.random(in: 10...150)
            let randomCategory = categories.randomElement() ?? "Miscellaneous"
            
            // Random date within the last 60 days (to test filtering)
            let randomDaysAgo = Int.random(in: 0...60)
            let randomDate = Calendar.current.date(byAdding: .day, value: -randomDaysAgo, to: Date()) ?? Date()
            
            let expense = Expense(name: randomName, amount: randomAmount, category: randomCategory, date: randomDate)
            dummyExpenses.append(expense)
        }
        
        self.expenses.append(contentsOf: dummyExpenses) // Append instead of overwrite
        saveExpenses()
        tableView.reloadData()
        refreshDashboard()
    }
}

// MARK: - TableView Extensions
extension ExpenseTrackerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Use FILTERED expenses for the row count
        return filteredExpenses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        // Grab the correct expense from the FILTERED list
        let expense = filteredExpenses[indexPath.row]

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
        case "Food": iconName = "fork.knife"; iconColor = .systemOrange
        case "Travel": iconName = "airplane"; iconColor = .systemBlue
        case "Miscellaneous": iconName = "bag.fill"; iconColor = .systemPurple
        case "Housing": iconName = "house.fill"; iconColor = .systemCyan
        case "Utilities": iconName = "bolt.fill"; iconColor = .systemYellow
        case "Groceries": iconName = "cart.fill"; iconColor = .systemMint
        case "Food & Dining": iconName = "fork.knife"; iconColor = .systemOrange
        case "Entertainment": iconName = "ticket.fill"; iconColor = .systemPurple
        case "Shopping": iconName = "bag.fill"; iconColor = .systemPink
        case "Health": iconName = "cross.case.fill"; iconColor = .systemRed
        default: iconName = "dollarsign.circle.fill"; iconColor = .systemGreen
        }

        content.image = UIImage(systemName: iconName)
        content.imageProperties.tintColor = iconColor
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.secondaryTextProperties.color = .secondaryLabel

        cell.contentConfiguration = content
        return cell
    }

    func didAddExpense(_ expense: Expense) {
        expenses.append(expense) // Save to master list
        tableView.reloadData()
        saveExpenses()
        refreshDashboard()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 1. Find the exact item in the FILTERED list
            let expenseToDelete = filteredExpenses[indexPath.row]
            
            // 2. Remove it from the MASTER list using its unique ID
            expenses.removeAll(where: { $0.id == expenseToDelete.id })
            
            // 3. Update UI and Save
            tableView.deleteRows(at: [indexPath], with: .fade)
            saveExpenses()
            refreshDashboard()
        }
    }
}
