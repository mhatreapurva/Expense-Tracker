// Models/Expense.swift
import Foundation

struct Expense: Identifiable {
    let id = UUID()
    var name: String
    var amount: Double
    var category: String
    var date: Date = Date()
}
