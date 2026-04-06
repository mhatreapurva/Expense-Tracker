import UIKit
import SwiftUI

class ExpenseTrackerViewController: UIViewController, AddExpenseDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var expenses: [Expense] = []
    private let defaults = UserDefaults.standard
    private let saveKey = "savedExpenses"

    private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    private var endDate: Date = Date()

    // ⭐️ NEW: Track the currently selected category from the chart
    private var selectedCategoryFilter: String?

    private var dashboardController: UIHostingController<DashboardView>?

    // ⭐️ NEW: Data for the Chart (Only filtered by Date)
    private var dateFilteredExpenses: [Expense] {
        return expenses.filter { $0.date >= startDate && $0.date <= endDate }
    }

    // ⭐️ NEW: Data for the Table (Filtered by Date AND Category)
    private var tableFilteredExpenses: [Expense] {
        if let category = selectedCategoryFilter {
            return dateFilteredExpenses.filter { $0.category == category }
        }
        return dateFilteredExpenses
    }

    // Reads the currency symbol from UserDefaults, defaults to "$" if none exists
    private var currencySymbol: String {
        return UserDefaults.standard.string(forKey: "currencySymbol") ?? "$"
    }

    struct MonthGroup {
        let date: Date
        let title: String
        var items: [Expense]
    }

    private var groupedExpenses: [MonthGroup] {
        let calendar = Calendar.current

        // Group using the tableFilteredExpenses so the list updates when a slice is tapped
        let grouped = Dictionary(grouping: tableFilteredExpenses) { expense -> Date in
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            return calendar.date(from: components) ?? expense.date
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        return grouped.map { (date, groupExpenses) in
            MonthGroup(
                date: date,
                title: formatter.string(from: date),
                items: groupExpenses.sorted(by: { $0.date > $1.date })
            )
        }.sorted { $0.date > $1.date }
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

    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            // This runs every time you switch back to this tab.
            // It forces the table to redraw, instantly applying any new currency symbol!
            tableView.reloadData()
            refreshDashboard()
        }
        


    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addExpense))
        let filterButton = UIBarButtonItem(image: UIImage(systemName: "calendar.badge.clock"), style: .plain, target: self, action: #selector(presentDateFilter))
        navigationItem.rightBarButtonItems = [addButton]

        let seedButton = UIBarButtonItem(title: "Seed", style: .plain, target: self, action: #selector(handleSeedTapped))
        let clearButton = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(clearAllData))
        clearButton.tintColor = .systemRed

        navigationItem.leftBarButtonItems = [filterButton, seedButton, clearButton]
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

        // Setup initial DashboardView
        let dashboardView = DashboardView(
            expenses: dateFilteredExpenses,
            selectedCategory: selectedCategoryFilter,
            onCategorySelected: { [weak self] category in
                self?.handleCategorySelection(category)
            }
        )

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

    // ⭐️ NEW: Handle tap from the SwiftUI Chart
    private func handleCategorySelection(_ category: String?) {
        // Update the filter state
        self.selectedCategoryFilter = category

        // Refresh the table with the new filtered data
        self.tableView.reloadData()

        // Refresh the dashboard so it visually updates the selected slice
        self.refreshDashboard()
    }

    private func refreshDashboard() {
        dashboardController?.rootView = DashboardView(
            expenses: dateFilteredExpenses,
            selectedCategory: selectedCategoryFilter,
            onCategorySelected: { [weak self] category in
                self?.handleCategorySelection(category)
            }
        )

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

    @objc private func clearAllData() {
        self.expenses.removeAll()
        defaults.removeObject(forKey: saveKey)
        self.selectedCategoryFilter = nil // Clear filter on reset
        self.tableView.reloadData()
        self.refreshDashboard()
    }

    @objc private func presentDateFilter() {
        let filterView = DateFilterView(startDate: self.startDate, endDate: self.endDate) { [weak self] newStart, newEnd in
            guard let self = self else { return }
            self.startDate = newStart
            self.endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: newEnd) ?? newEnd
            self.selectedCategoryFilter = nil // Reset drill-down when date changes
            self.tableView.reloadData()
            self.refreshDashboard()
        }

        let hostingController = UIHostingController(rootView: filterView)
        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(hostingController, animated: true)
    }

    // MARK: - Debugging Helpers
    private func seedData() {
        let categories = ["Housing", "Utilities", "Groceries", "Food & Dining", "Travel", "Entertainment", "Shopping", "Health", "Miscellaneous"]
        let names = ["Rent", "Electricity", "Whole Foods", "Dinner Out", "Uber", "Movie Night", "Amazon", "Gym", "Pharmacy"]

        var dummyExpenses: [Expense] = []

        for _ in 1...30 {
            let randomName = names.randomElement() ?? "Expense"
            let randomAmount = Double.random(in: 10...150)
            let randomCategory = categories.randomElement() ?? "Miscellaneous"
            let randomDaysAgo = Int.random(in: 0...90)
            let randomDate = Calendar.current.date(byAdding: .day, value: -randomDaysAgo, to: Date()) ?? Date()

            let expense = Expense(name: randomName, amount: randomAmount, category: randomCategory, date: randomDate)
            dummyExpenses.append(expense)
        }

        self.expenses.append(contentsOf: dummyExpenses)
        saveExpenses()
        self.selectedCategoryFilter = nil // Reset drill-down when new data is added
        tableView.reloadData()
        refreshDashboard()
    }
}

// MARK: - TableView Extensions
extension ExpenseTrackerViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return groupedExpenses.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedExpenses[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return groupedExpenses[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let expense = groupedExpenses[indexPath.section].items[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = expense.name

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateString = formatter.string(from: expense.date)

        let formattedAmount = String(format: "\(currencySymbol)%.2f", expense.amount)
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
        expenses.append(expense)
        if expense.date > endDate {
            endDate = expense.date
        }
        tableView.reloadData()
        saveExpenses()
        refreshDashboard()
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let expenseToDelete = groupedExpenses[indexPath.section].items[indexPath.row]
            let isLastInSection = groupedExpenses[indexPath.section].items.count == 1

            expenses.removeAll(where: { $0.id == expenseToDelete.id })

            if isLastInSection {
                tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
            } else {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }

            saveExpenses()
            refreshDashboard()
        }
    }
}
