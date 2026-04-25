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
    
    /// NEW: Sums all expenses that occurred in the current calendar month.
    var totalSpentInCurrentMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else { return 0 }
        
        return self.filter { expense in
            expense.date >= monthInterval.start && expense.date < monthInterval.end
        }.reduce(0) { $0 + $1.amount }
    }
}

extension Expense {
    /// Provides dummy data for seeding.
    static func seedDummyData(count: Int = 25) -> [Expense] {
        var dummy: [Expense] = []
        let today = Date()
        let calendar = Calendar.current
        
        let staticExpenses: [(name: String, amount: Double, category: String, daysAgo: Int)] = [
            ("Rent", 1200.0, "Housing", 2),
            ("Electricity", 85.50, "Utilities", 5),
            ("Whole Foods", 145.20, "Groceries", 1),
            ("Dinner Out", 65.0, "Food & Dining", 3),
            ("Uber", 15.0, "Travel", 4),
            ("Movie Night", 30.0, "Entertainment", 7),
            ("Amazon", 42.99, "Shopping", 10),
            ("Gym", 50.0, "Health", 12),
            ("Pharmacy", 22.50, "Health", 15),
            ("Internet", 60.0, "Utilities", 18),
            ("Trader Joe's", 80.0, "Groceries", 20),
            ("Coffee Shop", 5.50, "Food & Dining", 21),
            ("Subway", 12.0, "Food & Dining", 22),
            ("Gas Station", 45.0, "Travel", 25),
            ("Concert Ticket", 120.0, "Entertainment", 28),
            ("Target", 75.0, "Shopping", 30),
            ("Dentist", 150.0, "Health", 35),
            ("Water Bill", 40.0, "Utilities", 40),
            ("Farmers Market", 55.0, "Groceries", 45),
            ("Restaurant", 90.0, "Food & Dining", 50),
            ("Flight Booking", 350.0, "Travel", 60),
            ("Video Games", 60.0, "Entertainment", 65),
            ("Clothing", 110.0, "Shopping", 70),
            ("Doctor Visit", 200.0, "Health", 80),
            ("Hardware Store", 35.0, "Miscellaneous", 85)
        ]
        
        for item in staticExpenses {
            let date = calendar.date(byAdding: .day, value: -item.daysAgo, to: today) ?? today
            dummy.append(Expense(name: item.name, amount: item.amount, category: item.category, date: date))
        }
        
        return dummy
    }
}
