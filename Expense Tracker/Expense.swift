// Models/Expense.swift
import Foundation

/// The "Contract" for passing data back
protocol AddExpenseDelegate: AnyObject {
    func didAddExpense(_ expense: Expense)
}

struct Expense: Identifiable, Codable {
    var id = UUID()
    var name: String
    var amount: Double
    var category: String
    var date: Date = .init()
}
