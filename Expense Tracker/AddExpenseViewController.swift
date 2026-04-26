import UIKit
import Vision
import VisionKit // NEW: Imports Apple's native document scanning UI

/// NEW: Added VNDocumentCameraViewControllerDelegate
class AddExpenseViewController: UIViewController, VNDocumentCameraViewControllerDelegate {
    weak var delegate: AddExpenseDelegate?
    var expenseToEdit: Expense?

    /// NEW: The Scan Button
    private let scanButton = UIButton(type: .system)

    private let nameField = UITextField()
    private let amountField = UITextField()

    private let categoryButton = UIButton(type: .system)
    private var selectedCategory: String = "Housing"

    private let defaultCategories = [
        "Housing", "Utilities", "Groceries", "Food & Dining",
        "Travel", "Entertainment", "Shopping", "Health", "Miscellaneous",
    ]

    /// Merges built-in categories with any user-defined custom tags.
    private var categories: [String] {
        let custom = UserDefaults.standard.stringArray(forKey: "customCategories") ?? []
        return defaultCategories + custom
    }

    private let datePicker = UIDatePicker()
    private let recurringSwitch = UISwitch()
    private let intervalSegment = UISegmentedControl(items: ["Weekly", "Monthly", "Yearly"])

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "New Expense"

        setupNavigationBar()
        setupUI()
        setupKeyboardDismissal()
        setupCategoryMenu()
        
        if let expense = expenseToEdit {
            title = "Edit Expense"
            nameField.text = expense.name
            amountField.text = String(format: "%.2f", expense.amount)
            selectedCategory = expense.category
            categoryButton.setTitle(expense.category, for: .normal)
            datePicker.date = expense.date
            scanButton.isHidden = true
            
            // Hide recurring options when editing an existing single expense for now
            recurringSwitch.isHidden = true
            intervalSegment.isHidden = true
        }
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
    }

    private func setupUI() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.tintColor = .systemBlue
        datePicker.date = Date()
        datePicker.maximumDate = Date()

        let dateLabel = UILabel()
        dateLabel.text = "Date"
        dateLabel.textColor = .label
        let dateStack = UIStackView(arrangedSubviews: [dateLabel, datePicker])
        dateStack.axis = .horizontal
        dateStack.distribution = .fill

        // NEW: Style the Scan Button to look like a premium call-to-action
        var scanConfig = UIButton.Configuration.filled()
        scanConfig.title = "Scan Receipt"
        scanConfig.image = UIImage(systemName: "camera.viewfinder")
        scanConfig.imagePadding = 8
        scanConfig.cornerStyle = .medium
        scanButton.configuration = scanConfig
        scanButton.addTarget(self, action: #selector(scanTapped), for: .touchUpInside)

        // Recurring UI
        let recurringLabel = UILabel()
        recurringLabel.text = "Recurring Expense"
        recurringLabel.textColor = .label
        
        let recurringHStack = UIStackView(arrangedSubviews: [recurringLabel, recurringSwitch])
        recurringHStack.axis = .horizontal
        recurringHStack.distribution = .equalSpacing
        
        intervalSegment.selectedSegmentIndex = 1
        intervalSegment.isHidden = true
        recurringSwitch.addTarget(self, action: #selector(recurringToggled), for: .valueChanged)
        
        let recurringContainer = UIStackView(arrangedSubviews: [recurringHStack, intervalSegment])
        recurringContainer.axis = .vertical
        recurringContainer.spacing = 16
        
        // Added scanButton to the top of the stack
        let formStack = UIStackView(arrangedSubviews: [nameField, amountField, categoryButton, dateStack])
        formStack.axis = .vertical
        formStack.spacing = 16
        formStack.distribution = .fillEqually
        
        let mainStack = UIStackView(arrangedSubviews: [scanButton, formStack, recurringContainer])
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.distribution = .fill

        view.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        for item in [nameField, amountField, categoryButton] {
            item.backgroundColor = .secondarySystemGroupedBackground
            item.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        
        for item in [nameField, amountField] {
            item.textColor = .label
            item.tintColor = .systemBlue
            item.borderStyle = .none
            item.layer.cornerRadius = 10
            item.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 10))
            item.leftViewMode = .always
        }

        nameField.placeholder = "Expense Name (e.g. Netflix)"
        amountField.placeholder = "Amount (e.g. 15.99)"
        amountField.keyboardType = .decimalPad

        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .label
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        config.background.backgroundColor = .secondarySystemGroupedBackground
        config.background.cornerRadius = 10
        categoryButton.configuration = config
        categoryButton.contentHorizontalAlignment = .leading

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scanButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add tap gesture to dismiss keyboard when tapping outside
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func recurringToggled() {
        UIView.animate(withDuration: 0.3) {
            self.intervalSegment.isHidden = !self.recurringSwitch.isOn
            self.view.layoutIfNeeded()
        }
    }

    private func setupKeyboardDismissal() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [flexSpace, doneButton]
        amountField.inputAccessoryView = toolbar
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setupCategoryMenu() {
        categoryButton.setTitle(selectedCategory, for: .normal)
        rebuildCategoryMenu()
        categoryButton.showsMenuAsPrimaryAction = true
    }

    private func rebuildCategoryMenu() {
        let menuActions = categories.map { category in
            UIAction(title: category, state: category == selectedCategory ? .on : .off) { [weak self] action in
                self?.selectedCategory = action.title
                self?.categoryButton.setTitle(action.title, for: .normal)
                self?.rebuildCategoryMenu() // refresh checkmarks
            }
        }

        let addCustomAction = UIAction(
            title: "＋ Add Custom Tag…",
            image: UIImage(systemName: "tag.fill"),
            attributes: []
        ) { [weak self] _ in
            self?.promptForCustomCategory()
        }

        let categoriesMenu = UIMenu(title: "", options: .displayInline, children: menuActions)
        let addMenu = UIMenu(title: "", options: .displayInline, children: [addCustomAction])

        categoryButton.menu = UIMenu(title: "Select Category", children: [categoriesMenu, addMenu])
    }

    private func promptForCustomCategory() {
        let alert = UIAlertController(title: "New Custom Tag", message: "Enter a name for your new expense category.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "e.g. Subscriptions"
            textField.autocapitalizationType = .words
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let newTag = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newTag.isEmpty else { return }

            // Prevent duplicates
            guard !self.categories.contains(newTag) else {
                self.selectedCategory = newTag
                self.categoryButton.setTitle(newTag, for: .normal)
                self.rebuildCategoryMenu()
                return
            }

            // Persist the new custom tag
            var custom = UserDefaults.standard.stringArray(forKey: "customCategories") ?? []
            custom.append(newTag)
            UserDefaults.standard.set(custom, forKey: "customCategories")

            // Select the new tag immediately
            self.selectedCategory = newTag
            self.categoryButton.setTitle(newTag, for: .normal)
            self.rebuildCategoryMenu()
        })

        present(alert, animated: true)
    }

    // MARK: - Scanner Logic

    @objc private func scanTapped() {
        // Create and present the native Apple document scanner
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
    }

    // Delegate: What happens when they successfully scan a document
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        if scan.pageCount > 0 {
            let scannedImage = scan.imageOfPage(at: 0)
            print("SUCCESS! Captured a perfectly cropped receipt image of size: \(scannedImage.size)")

            // NEW: Feed the image into the Vision network!
            processReceiptImage(scannedImage)
        }

        controller.dismiss(animated: true)
    }

    // Delegate: What happens if they hit cancel
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }

    // Delegate: What happens if the camera breaks
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print("Scanner Error: \(error.localizedDescription)")
        controller.dismiss(animated: true)
    }

    // MARK: - Phase 2: OCR Pipeline

    private func processReceiptImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        // 1. Create the request handler
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        // 2. Create the text recognition request
        // 2. Create the text recognition request
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                return
            }

            // 3. Extract the raw string from every line
            let extractedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            // 4. Pass the messy text to our Intelligence Engine
            let parsedData = self?.extractExpenseData(from: extractedText)

            // 5. Jump back to the Main Thread to update the UI
            // 5. Jump back to the Main Thread to update the UI
            DispatchQueue.main.async {
                // --- NEW: Run the Predictor ---
                let finalName = parsedData?.name ?? "Unknown"
                let predictedCategory = self?.predictCategory(for: finalName) ?? "Miscellaneous"

                // Update internal state
                self?.selectedCategory = predictedCategory

                // Update the UI Button Text
                self?.categoryButton.setTitle(predictedCategory, for: .normal)

                // Set the Name
                self?.nameField.text = finalName

                // Set the Amount
                if let amount = parsedData?.amount {
                    self?.amountField.text = String(format: "%.2f", amount)
                }

                // Set the Date
                if let date = parsedData?.date {
                    self?.datePicker.date = date
                }

                // UI Polish: Make ALL auto-filled fields flash green
                UIView.animate(withDuration: 0.3, animations: {
                    self?.nameField.backgroundColor = .systemGreen.withAlphaComponent(0.2)
                    self?.amountField.backgroundColor = .systemGreen.withAlphaComponent(0.2)
                    self?.categoryButton.configuration?.background.backgroundColor = .systemGreen.withAlphaComponent(0.2)
                }) { _ in
                    UIView.animate(withDuration: 1.0) {
                        self?.nameField.backgroundColor = .secondarySystemGroupedBackground
                        self?.amountField.backgroundColor = .secondarySystemGroupedBackground
                        self?.categoryButton.configuration?.background.backgroundColor = .secondarySystemGroupedBackground
                    }
                }
            }
        }
        // We want accurate text, not fast text (Crucial for decimals and receipts)
        request.recognitionLevel = .accurate

        // Use Apple's built-in spellcheck to fix slightly blurry letters
        request.usesLanguageCorrection = true

        // 5. Fire the neural network on a background thread
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform OCR: \(error)")
            }
        }
    }

    // MARK: - Phase 3: NLP & Regex Parser

    private func extractExpenseData(from lines: [String]) -> (name: String, amount: Double?, date: Date?) {
        var detectedName = "Unknown Merchant"
        var detectedAmount: Double?
        var detectedDate: Date?

        let fullText = lines.joined(separator: " ")

        // 1. EXTRACT NAME (Heuristic: It's usually the very first line of a receipt)
        if let firstLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            detectedName = firstLine
        }

        // 2. EXTRACT DATE (Apple's Native NLP Engine)
        // NSDataDetector is highly optimized to find dates in messy text
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            let matches = detector.matches(in: fullText, options: [], range: NSRange(location: 0, length: fullText.utf16.count))
            // Grab the first date it finds (Receipt dates are usually near the top)
            if let firstMatch = matches.first, let date = firstMatch.date {
                detectedDate = date
            }
        }

        // 3. EXTRACT AMOUNT (Regex + Logic)
        // Receipts have many numbers (taxes, subtotals, unit prices).
        // The "Total" is almost always the largest currency-formatted number.
        do {
            // Regex: Looks for an optional $, optional spaces, and digits with a decimal (e.g., "$154.06" or "145.00")
            let regex = try NSRegularExpression(pattern: "\\$?\\s*(\\d+[\\.,]\\d{2})")

            var allAmounts: [Double] = []
            let results = regex.matches(in: fullText, range: NSRange(fullText.startIndex..., in: fullText))

            for result in results {
                if let range = Range(result.range(at: 1), in: fullText) {
                    // Replace commas with dots in case of European formatting, then convert to Double
                    let cleanNumberString = String(fullText[range]).replacingOccurrences(of: ",", with: ".")
                    if let amount = Double(cleanNumberString) {
                        allAmounts.append(amount)
                    }
                }
            }

            // The Receipt Total is logically the highest number on the page
            detectedAmount = allAmounts.max()

        } catch {
            print("Regex error: \(error)")
        }

        return (detectedName, detectedAmount, detectedDate)
    }

    // MARK: - Phase 4: Smart Category Predictor

    private func predictCategory(for merchantName: String) -> String {
        // Lowercase the text so our keyword matching is case-insensitive
        let lowercasedName = merchantName.lowercased()

        // Our "Pre-Trained" Heuristic Model
        let categoryRules: [String: [String]] = [
            "Food & Dining": ["cafe", "grill", "kitchen", "starbucks", "restaurant", "pizza", "burger", "coffee", "taco", "diner", "bakery"],
            "Groceries": ["market", "grocery", "whole foods", "target", "walmart", "trader", "safeway", "kroger", "costco"],
            "Travel": ["uber", "lyft", "taxi", "airlines", "hotel", "motel", "transit", "train", "flight"],
            "Utilities": ["electric", "power", "water", "gas", "internet", "telecom", "verizon", "comcast", "repair", "auto"],
            "Shopping": ["amazon", "best buy", "apple", "mall", "boutique", "store", "clothing"],
            "Health": ["pharmacy", "cvs", "walgreens", "hospital", "clinic", "dental", "doctor"],
        ]

        // Scan the merchant name for any of our keywords
        for (category, keywords) in categoryRules {
            for keyword in keywords {
                if lowercasedName.contains(keyword) {
                    print("AI categorized '\(merchantName)' as '\(category)' based on keyword: '\(keyword)'")
                    return category
                }
            }
        }

        // If the AI has no idea, safely fallback to the default
        print("AI could not classify '\(merchantName)', defaulting to Miscellaneous.")
        return "Miscellaneous"
    }

    // MARK: - Save Logic

    @objc private func saveTapped() {
        guard let name = nameField.text, !name.isEmpty,
              let amountText = amountField.text, let amount = Double(amountText)
        else {
            let alert = UIAlertController(title: "Missing Information", message: "Please ensure all fields are filled out correctly.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        if var expense = expenseToEdit {
            expense.name = name
            expense.amount = amount
            expense.category = selectedCategory
            expense.date = datePicker.date
            delegate?.didEditExpense(expense)
        } else {
            let newExpense = Expense(name: name, amount: amount, category: selectedCategory, date: datePicker.date)
            
            // Handle Recurring Subscriptions
            if recurringSwitch.isOn {
                let intervalMap: [Int: SubscriptionInterval] = [0: .weekly, 1: .monthly, 2: .yearly]
                let interval = intervalMap[intervalSegment.selectedSegmentIndex] ?? .monthly
                
                // The next due date is exactly one interval away from the chosen date
                let nextDate = interval.nextDate(after: datePicker.date)
                
                let subscription = Subscription(name: name, amount: amount, category: selectedCategory, interval: interval, nextDueDate: nextDate)
                SubscriptionManager.shared.addSubscription(subscription)
            }
            
            delegate?.didAddExpense(newExpense)
        }
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}
