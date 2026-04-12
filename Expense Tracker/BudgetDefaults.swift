import Foundation

// NEW: Enum to define the budgeting interval
public enum BudgetInterval: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"

    public var id: String { self.rawValue }

    // Helper to get remaining time unit in the current month
    func remainingTimeUnits(for date: Date) -> Int {
        let calendar = Calendar.current
        switch self {
        case .daily:
            // Will now resolve to the definition in Date+DaysRemaining.swift
            return date.daysRemainingInMonthIncludingToday 
        case .weekly:
            // Calculate remaining weeks. This is an approximation.
            // Start of current week to end of month, divided by 7.
            // We want at least 1 if there's any time left.
            let startOfToday = calendar.startOfDay(for: date)
            guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: calendar.startOfDay(for: date).startOfMonth()) else { return 1 }
            
            let daysRemaining = calendar.dateComponents([.day], from: startOfToday, to: endOfMonth).day ?? 0
            // Ensure at least 1 unit if there are days remaining, otherwise 0
            return max(1, Int(ceil(Double(daysRemaining) / 7.0)))
        case .monthly:
            return 1 // For monthly, we just return the full remaining budget, so the unit is 1 month.
        }
    }
}

/// A tiny helper to manage the user's monthly budget in UserDefaults.
/// Stores and retrieves a Double under a stable key.
public enum BudgetDefaults {
    private static let monthlyBudgetKey = "monthlyBudget"
    private static let isBudgetingEnabledKey = "isBudgetingEnabled"
    // NEW: Key for the budgeting interval setting
    private static let budgetIntervalKey = "budgetInterval"

    /// Persists the monthly budget value in UserDefaults.
    /// - Parameter amount: The budget amount for the month.
    public static func setMonthlyBudget(_ amount: Double) {
        UserDefaults.standard.set(amount, forKey: monthlyBudgetKey)
    }

    /// Retrieves the monthly budget value from UserDefaults.
    /// If no value has been saved yet, this returns 0.0.
    public static func getMonthlyBudget() -> Double {
        UserDefaults.standard.double(forKey: monthlyBudgetKey)
    }

    /// Persists the budgeting enabled state in UserDefaults.
    /// - Parameter enabled: A boolean indicating if budgeting is enabled.
    public static func setIsBudgetingEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: isBudgetingEnabledKey)
    }

    /// Retrieves the budgeting enabled state from UserDefaults.
    /// If no value has been saved yet, this returns true (budgeting enabled by default).
    public static func getIsBudgetingEnabled() -> Bool {
        // Default to true if not set
        UserDefaults.standard.object(forKey: isBudgetingEnabledKey) as? Bool ?? true
    }

    // NEW: Persists the budgeting interval in UserDefaults.
    /// - Parameter interval: The selected BudgetInterval.
    public static func setBudgetInterval(_ interval: BudgetInterval) {
        UserDefaults.standard.set(interval.rawValue, forKey: budgetIntervalKey)
    }

    // NEW: Retrieves the budgeting interval from UserDefaults.
    /// If no value has been saved yet, this returns .daily (default).
    public static func getBudgetInterval() -> BudgetInterval {
        if let rawValue = UserDefaults.standard.string(forKey: budgetIntervalKey),
           let interval = BudgetInterval(rawValue: rawValue) {
            return interval
        }
        return .daily // Default to daily
    }
}

// NEW: Date Extensions for budgeting calculations
extension Date {
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }
}
