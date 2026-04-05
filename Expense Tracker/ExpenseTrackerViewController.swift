// Views/ExpenseTrackerViewController.swift
import UIKit

class ExpenseTrackerViewController: UIViewController {
    private var expenses: [Expense] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Add a button to add new expenses
        let addButton = UIBarButtonItem(title: "New Expense", style: .plain, target: self, action: #selector(addExpense))
        navigationItem.rightBarButtonItem = addButton
        
        // Add a table view to show expenses
        let tableView = UITableView()
        tableView.register(ExpenseCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        
        // Basic constraints
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func addExpense() {
        // Implement logic to add a new expense
    }
}

extension ExpenseTrackerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expenses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        // Configure the cell with expense data
        return cell
    }
}
