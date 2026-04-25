import AppIntents
import Foundation

/// The intent that Siri fires to add a new expense.
struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    static var description = IntentDescription("Adds a new expense to your tracker.")

    @Parameter(title: "Expense Name", description: "The name of the expense, e.g., Starbucks")
    var name: String

    @Parameter(title: "Amount", description: "The amount spent")
    var amount: Double?

    // Defines how the shortcut appears in the Shortcuts app and Siri's understanding
    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$name) expense") {
            \.$amount
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let finalAmount = amount ?? 0.0
        
        // Load existing expenses
        var currentExpenses: [Expense] = []
        if let data = UserDefaults.standard.data(forKey: "savedExpenses"),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            currentExpenses = decoded
        }
        
        // Create and append the new expense
        let newExpense = Expense(name: name, amount: finalAmount, category: "Miscellaneous", date: Date())
        currentExpenses.append(newExpense)
        
        // Save back to UserDefaults
        if let encoded = try? JSONEncoder().encode(currentExpenses) {
            UserDefaults.standard.set(encoded, forKey: "savedExpenses")
        }
        
        // Post a notification so the UI can refresh if the app is active
        NotificationCenter.default.post(name: NSNotification.Name("ExpensesUpdated"), object: nil)

        let amountString = amount != nil ? " for \(finalAmount)" : ""
        return .result(dialog: "OK. Added \(name) expense\(amountString).")
    }
}

/// Provides the "App Shortcut" so users can just say the phrase without manual setup.
struct ExpenseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add an expense in \(.applicationName)",
                "Add expense in \(.applicationName)",
                "Track an expense in \(.applicationName)"
            ],
            shortTitle: "Add Expense",
            systemImageName: "plus.circle"
        )
    }
}
