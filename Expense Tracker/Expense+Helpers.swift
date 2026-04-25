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
    
    // NEW FOR ANALYTICS
    func groupedByCategory() -> [(category: String, amount: Double)] {
        let dict = Dictionary(grouping: self, by: { $0.category })
        return dict.map { (category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }
    
    func groupedByDay() -> [(date: Date, amount: Double)] {
        let calendar = Calendar.current
        let dict = Dictionary(grouping: self) { expense -> Date in
            calendar.startOfDay(for: expense.date)
        }
        return dict.map { (date: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.date < $1.date }
    }
    
    func groupedByMonthForBarChart() -> [(date: Date, amount: Double)] {
        let calendar = Calendar.current
        let dict = Dictionary(grouping: self) { expense -> Date in
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            return calendar.date(from: components) ?? expense.date
        }
        return dict.map { (date: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.date < $1.date }
    }
}
