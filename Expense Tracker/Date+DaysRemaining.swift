import Foundation

public extension Date {
    /// Calculates the number of days remaining in the current calendar month, including today.
    /// If it's the last day of the month, returns 1 to avoid divide-by-zero in daily budgets.
    var daysRemainingInMonthIncludingToday: Int {
        let calendar = Calendar.current
        // Start of today
        let startOfToday = calendar.startOfDay(for: self)

        // Determine the range of days in this month
        guard let range = calendar.range(of: .day, in: .month, for: startOfToday),
              let day = calendar.dateComponents([.day], from: startOfToday).day else {
            return 1
        }

        let totalDays = range.count
        let remaining = totalDays - day + 1 // include today
        return max(remaining, 1)
    }
}
