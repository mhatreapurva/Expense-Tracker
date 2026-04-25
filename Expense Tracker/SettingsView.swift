import SwiftUI
import UIKit

struct SettingsView: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("currencySymbol") private var currencySymbol: String = "$"
    @AppStorage("monthlyBudget") private var monthlyBudget: Double = 0.0
    @AppStorage("isBudgetingEnabled") private var isBudgetingEnabled: Bool = true
    // NEW: AppStorage for budgeting interval
    @AppStorage("budgetInterval") private var budgetInterval: BudgetInterval = .daily
    
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss


    let currencies = [
        "US Dollar ($)": "$",
        "Euro (€)": "€",
        "British Pound (£)": "£",
        "Indian Rupee (₹)": "₹",
        "Japanese Yen (¥)": "¥",
    ]

    var body: some View {
        NavigationView {
            Form {
                // --- PROFILE SECTION ---
                Section(header: Text("Profile"), footer: Text("Enter your name to personalize your dashboard.")) {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)

                        TextField("Enter your name", text: $userName)
                            .font(.headline)
                            .padding(.leading, 8)

                        Spacer()

                        if !userName.isEmpty {
                            Button(action: { userName = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // NEW: BUDGET SECTION
                Section(header: Text("Budgeting"), footer: Text("Setting a monthly budget helps calculate your 'Safe to Spend' daily allowance.")) {
                    Toggle("Enable Monthly Budget", isOn: $isBudgetingEnabled)
                        .onChange(of: isBudgetingEnabled) { oldValue, newValue in
                            BudgetDefaults.setIsBudgetingEnabled(newValue)
                        }

                    HStack {
                        Text("Monthly Budget")
                        Spacer()
                        TextField("Amount", value: $monthlyBudget, format: .currency(code: currencyCode))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .disabled(!isBudgetingEnabled)
                    }
                    .opacity(isBudgetingEnabled ? 1.0 : 0.6)

                    // NEW: Picker for budget interval
                    Picker("Show Safe to Spend", selection: $budgetInterval) {
                        ForEach(BudgetInterval.allCases) { interval in
                            Text(interval.rawValue).tag(interval)
                        }
                    }
                    .disabled(!isBudgetingEnabled)
                    .opacity(isBudgetingEnabled ? 1.0 : 0.6)
                    .onChange(of: budgetInterval) { oldValue, newValue in
                        BudgetDefaults.setBudgetInterval(newValue)
                    }
                }

                // --- PREFERENCES SECTION ---
                Section(header: Text("Preferences")) {
                    Picker("Currency", selection: $currencySymbol) {
                        ForEach(currencies.keys.sorted(), id: \.self) { key in
                            Text(key).tag(currencies[key]!)
                        }
                    }
                }

                // --- EXPORT SECTION ---
                Section(header: Text("Data Management"), footer: Text("Manage test data and export your raw data for use in Excel, Numbers, or Python.")) {
                    if FeatureFlags.enableDeveloperTools {
                        Button(action: {
                            NotificationCenter.default.post(name: NSNotification.Name("SeedDataNotification"), object: nil)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Seed Test Data")
                            }
                            .foregroundColor(.blue)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                    
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clear All Data")
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .alert("Clear All Data?", isPresented: $showDeleteAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete Everything", role: .destructive) {
                            NotificationCenter.default.post(name: NSNotification.Name("ClearDataNotification"), object: nil)
                            dismiss()
                        }
                    } message: {
                        Text("This will permanently delete all your expenses and subscriptions. This action cannot be undone.")
                    }
                    
                    Button(action: exportCSV) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Expenses to CSV")
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .onAppear {
                // Ensure BudgetDefaults are in sync with AppStorage on appear
                BudgetDefaults.setIsBudgetingEnabled(isBudgetingEnabled)
                BudgetDefaults.setBudgetInterval(budgetInterval) // NEW: Sync interval
            }
        }
    }
    
    // Helper to get currency code from symbol for the TextField formatter
    private var currencyCode: String {
        switch currencySymbol {
        case "€": return "EUR"
        case "£": return "GBP"
        case "₹": return "INR"
        case "¥": return "JPY"
        default: return "USD"
        }
    }

    private func exportCSV() {
        let saveKey = "savedExpenses"
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let expenses = try? JSONDecoder().decode([Expense].self, from: data),
              !expenses.isEmpty
        else {
            return
        }

        var csvString = "Date,Expense Name,Category,Amount\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for expense in expenses {
            let dateString = formatter.string(from: expense.date)
            let sanitizedName = expense.name.replacingOccurrences(of: "\"", with: "\"\"")
            let row = "\(dateString),\"\(sanitizedName)\",\(expense.category),\(expense.amount)\n"
            csvString.append(row)
        }

        let fileName = "Expenses_Export_\(formatter.string(from: Date())).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            
            try csvString.write(to: path, atomically: true, encoding: .utf8)
            presentShareSheet(with: path)
        } catch {
            print("Failed to create CSV file: \(error)")
        }
    }

    private func presentShareSheet(with url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }),
           let rootVC = window.rootViewController
        {
            if UIDevice.current.userInterfaceIdiom == .pad {
                activityVC.popoverPresentationController?.sourceView = window
                activityVC.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                activityVC.popoverPresentationController?.permittedArrowDirections = []
            }

            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }

            topController.present(activityVC, animated: true)
        }
    }
}

/// A button style that scales down slightly and triggers haptic feedback on press.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                }
            }
    }
}
