import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("currencySymbol") private var currencySymbol: String = "$"
    
    let currencies = [
        "US Dollar ($)": "$",
        "Euro (€)": "€",
        "British Pound (£)": "£",
        "Indian Rupee (₹)": "₹",
        "Japanese Yen (¥)": "¥"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // --- PROFILE SECTION ---
                Section(header: Text("Profile"), footer: Text("Enter your name to personalize your dashboard.")) {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue) // Correct SwiftUI Color
                        
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
                
                // --- PREFERENCES SECTION ---
                Section(header: Text("Preferences")) {
                    Picker("Currency", selection: $currencySymbol) {
                        ForEach(currencies.keys.sorted(), id: \.self) { key in
                            Text(key).tag(currencies[key]!)
                        }
                    }
                }
                
                // --- EXPORT SECTION ---
                Section(header: Text("Data Management"), footer: Text("Export your raw data for use in Excel, Numbers, or Python.")) {
                    Button(action: exportCSV) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Expenses to CSV")
                        }
                        .foregroundColor(.blue) // Replaces .systemBlue
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func exportCSV() {
        let saveKey = "savedExpenses"
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let expenses = try? JSONDecoder().decode([Expense].self, from: data),
              !expenses.isEmpty else {
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
           let rootVC = window.rootViewController {
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                activityVC.popoverPresentationController?.sourceView = window
                activityVC.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                activityVC.popoverPresentationController?.permittedArrowDirections = []
            }
            
            // If the root is a TabBar or NavController, we should find the currently visible child to present from
            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }
            
            topController.present(activityVC, animated: true)
        }
    }
}
