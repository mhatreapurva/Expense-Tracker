import Foundation

class SubscriptionManager {
    static let shared = SubscriptionManager()
    private let storageKey = "savedSubscriptions"
    
    var subscriptions: [Subscription] = []
    
    init() {
        loadSubscriptions()
    }
    
    func loadSubscriptions() {
        if let savedData = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Subscription].self, from: savedData) {
            subscriptions = decoded
        }
    }
    
    func saveSubscriptions() {
        if let encoded = try? JSONEncoder().encode(subscriptions) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    func addSubscription(_ subscription: Subscription) {
        subscriptions.append(subscription)
        saveSubscriptions()
    }
    
    func removeSubscription(id: UUID) {
        subscriptions.removeAll { $0.id == id }
        saveSubscriptions()
    }
    
    /// Checks all subscriptions and generates new expenses if their nextDueDate is in the past or today.
    /// Returns the generated expenses to be saved by the main view controller.
    func processDueSubscriptions() -> [Expense] {
        var generatedExpenses: [Expense] = []
        let now = Date()
        
        for i in 0..<subscriptions.count {
            var sub = subscriptions[i]
            
            // Loop in case it's overdue by multiple intervals
            while sub.nextDueDate <= now {
                let newExpense = Expense(name: sub.name, amount: sub.amount, category: sub.category, date: sub.nextDueDate)
                generatedExpenses.append(newExpense)
                
                // Advance to next due date
                sub.nextDueDate = sub.interval.nextDate(after: sub.nextDueDate)
            }
            
            subscriptions[i] = sub
        }
        
        if !generatedExpenses.isEmpty {
            saveSubscriptions()
        }
        
        return generatedExpenses
    }
}
