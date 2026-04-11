// Expense+Helpers.swift
import Foundation

extension Array where Element == Expense {
    /// Returns expenses filtered by the given date range.
    func filtered(by startDate: Date, endDate: Date) -> [Expense] {
        filter { $0.date >= startDate && $0.date <= endDate }
    }

    /// Returns expenses filtered by a category string.
    func filtered(byCategory category: String?) -> [Expense] {
        guard let category = category else { return self }
        return filter { $0.category == category }
    }

    /// Returns expenses filtered by a search text (name or category, case-insensitive).
    func filtered(bySearch search: String) -> [Expense] {
        guard !search.isEmpty else { return self }
        return filter {
            $0.name.localizedCaseInsensitiveContains(search) ||
            $0.category.localizedCaseInsensitiveContains(search)
        }
    }

    /// Groups expenses by month and year.
    func groupedByMonth() -> [(date: Date, title: String, items: [Expense])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: self) { expense -> Date in
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            return calendar.date(from: components) ?? expense.date
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return grouped.map { date, expenses in
            (date: date, title: formatter.string(from: date), items: expenses.sorted { $0.date > $1.date })
        }.sorted { $0.date > $1.date }
    }
}

extension Expense {
    /// Provides dummy data for seeding.
    static func seedDummyData(count: Int = 30) -> [Expense] {
        let categories = ["Housing", "Utilities", "Groceries", "Food & Dining", "Travel", "Entertainment", "Shopping", "Health", "Miscellaneous"]
        let names = ["Rent", "Electricity", "Whole Foods", "Dinner Out", "Uber", "Movie Night", "Amazon", "Gym", "Pharmacy"]
        var dummy: [Expense] = []
        for _ in 0..<count {
            let name = names.randomElement() ?? "Expense"
            let amount = Double.random(in: 10...150)
            let category = categories.randomElement() ?? "Miscellaneous"
            let daysAgo = Int.random(in: 0...90)
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            dummy.append(Expense(name: name, amount: amount, category: category, date: date))
        }
        return dummy
    }
}
