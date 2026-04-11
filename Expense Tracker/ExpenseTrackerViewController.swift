import SwiftUI
import UIKit
import Foundation

class ExpenseTrackerViewController: UIViewController, AddExpenseDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var expenses: [Expense] = []

    // ⭐️ NEW: The Search Controller
    private let searchController = UISearchController(searchResultsController: nil)
    private var searchText: String = ""

    private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    private var endDate: Date = .init()
    private var selectedCategoryFilter: String?

    private var dashboardController: UIHostingController<DashboardView>?

    private var currencySymbol: String {
        return UserDefaults.standard.string(forKey: "currencySymbol") ?? "$"
    }

    /// Pipeline Stage 1: Date Filter (Used for the Chart)
    private var dateFilteredExpenses: [Expense] {
        expenses.filtered(by: startDate, endDate: endDate)
    }

    /// Pipeline Stage 2 & 3: Category Drill-Down & Text Search (Used for the Table)
    private var tableFilteredExpenses: [Expense] {
        expenses
            .filtered(by: startDate, endDate: endDate)
            .filtered(byCategory: selectedCategoryFilter)
            .filtered(bySearch: searchText)
    }

    private var groupedExpenses: [(date: Date, title: String, items: [Expense])] {
        tableFilteredExpenses.groupedByMonth()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Expenses"
        navigationController?.navigationBar.prefersLargeTitles = true

        setupSearchController() // ⭐️ Initialize Search
        setupTableView()
        setupNavigationBar()
        loadExpenses()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        refreshDashboard()
    }

    /// ⭐️ NEW: Setup the native Search Bar
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by name or category..."

        // Attach it to the Navigation Bar
        navigationItem.searchController = searchController

        // Ensure the search bar doesn't remain on screen if the user navigates away
        definesPresentationContext = true
    }

    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addExpense))
        let filterButton = UIBarButtonItem(image: UIImage(systemName: "calendar.badge.clock"), style: .plain, target: self, action: #selector(presentDateFilter))
        navigationItem.rightBarButtonItems = [addButton]

//        let seedButton = UIBarButtonItem(title: "Seed", style: .plain, target: self, action: #selector(handleSeedTapped))
//        let clearButton = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(clearAllData))
//        clearButton.tintColor = .systemRed

//        navigationItem.leftBarButtonItems = [filterButton, seedButton, clearButton]
        navigationItem.leftBarButtonItem = filterButton
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
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let dashboardView = DashboardView(expenses: dateFilteredExpenses, selectedCategory: selectedCategoryFilter) { [weak self] category in
            self?.handleCategorySelection(category)
        }

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

    private func handleCategorySelection(_ category: String?) {
        selectedCategoryFilter = category
        tableView.reloadData()
        refreshDashboard()
    }

    private func refreshDashboard() {
        dashboardController?.rootView = DashboardView(expenses: dateFilteredExpenses, selectedCategory: selectedCategoryFilter) { [weak self] category in
            self?.handleCategorySelection(category)
        }

        if let headerView = dashboardController?.view {
            let targetSize = headerView.sizeThatFits(CGSize(width: view.frame.width, height: UIView.layoutFittingExpandedSize.height))
            headerView.frame.size.height = targetSize.height
            tableView.tableHeaderView = headerView
        }
    }

    private func saveExpenses() {
        if let encodedData = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encodedData, forKey: "savedExpenses")
        }
    }

    private func loadExpenses() {
        if let savedData = UserDefaults.standard.data(forKey: "savedExpenses") {
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
        if let sheet = navController.sheetPresentationController { sheet.detents = [.medium(), .large()] }
        present(navController, animated: true)
    }

    @objc private func handleSeedTapped() {
        seedData()
    }

    @objc private func clearAllData() {
        expenses.removeAll()
        UserDefaults.standard.removeObject(forKey: "savedExpenses")
        selectedCategoryFilter = nil
        tableView.reloadData()
        refreshDashboard()
    }

    @objc private func presentDateFilter() {
        let filterView = DateFilterView(startDate: startDate, endDate: endDate) { [weak self] newStart, newEnd in
            guard let self = self else { return }
            self.startDate = newStart
            self.endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: newEnd) ?? newEnd
            self.selectedCategoryFilter = nil
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
        expenses.append(contentsOf: Expense.seedDummyData())
        saveExpenses()
        selectedCategoryFilter = nil
        tableView.reloadData()
        refreshDashboard()
    }
}

/// ⭐️ NEW: Handle the Search Bar text changing
extension ExpenseTrackerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        // Grab the text, convert to lowercase for easy matching, and reload the table
        searchText = searchController.searchBar.text ?? ""
        tableView.reloadData()
    }
}

// MARK: - TableView Extensions

extension ExpenseTrackerViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in _: UITableView) -> Int {
        return groupedExpenses.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedExpenses[section].items.count
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
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

        let iconName: String; let iconColor: UIColor
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
        if expense.date > endDate { endDate = expense.date }
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

