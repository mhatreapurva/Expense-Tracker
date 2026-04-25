import Foundation

/// Computes the per-day safe-to-spend amount based on the user's monthly budget
/// and how much they've spent so far in the current month.
public enum SafeToSpendCalculator {
    /// Calculates the safe-to-spend amount for today based on the selected interval.
    /// - Parameters:
    ///   - totalSpentThisMonth: Sum of all expenses in the current month.
    ///   - date: The date to use for calculation (defaults to today).
    ///   - interval: The BudgetInterval (daily, weekly, monthly) for calculation.
    /// - Returns: The per-unit amount the user can safely spend. Returns 0 if negative, or Double.infinity if budgeting is disabled.
    public static func calculateSafeToSpend(totalSpentThisMonth: Double, on date: Date = Date(), for interval: BudgetInterval) -> Double { // MODIFIED: Added interval parameter
        // NEW: Check if budgeting is enabled
        guard BudgetDefaults.getIsBudgetingEnabled() else {
            return .infinity // If budgeting is disabled, safe to spend is unlimited
        }

        let monthlyBudget = BudgetDefaults.getMonthlyBudget()
        let remainingBudget = monthlyBudget - totalSpentThisMonth

        // NEW: Calculate based on the selected interval
        let timeUnitsRemaining = interval.remainingTimeUnits(for: date)

        // Avoid divide-by-zero, timeUnitsRemaining is guaranteed to be at least 1 by BudgetInterval enum
        let perUnit = remainingBudget / Double(timeUnitsRemaining)
        return perUnit
    }
}
