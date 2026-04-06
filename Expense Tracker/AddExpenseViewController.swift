import UIKit
import Vision
import VisionKit // ⭐️ NEW: Imports Apple's native document scanning UI

/// ⭐️ NEW: Added VNDocumentCameraViewControllerDelegate
class AddExpenseViewController: UIViewController, VNDocumentCameraViewControllerDelegate {
    weak var delegate: AddExpenseDelegate?

    /// ⭐️ NEW: The Scan Button
    private let scanButton = UIButton(type: .system)

    private let nameField = UITextField()
    private let amountField = UITextField()

    private let categoryButton = UIButton(type: .system)
    private var selectedCategory: String = "Housing"

    private let categories = [
        "Housing", "Utilities", "Groceries", "Food & Dining",
        "Travel", "Entertainment", "Shopping", "Health", "Miscellaneous",
    ]

    private let datePicker = UIDatePicker()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "New Expense"

        setupNavigationBar()
        setupUI()
        setupCategoryMenu()
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

        // ⭐️ NEW: Style the Scan Button to look like a premium call-to-action
        var scanConfig = UIButton.Configuration.filled()
        scanConfig.title = "Scan Receipt"
        scanConfig.image = UIImage(systemName: "camera.viewfinder")
        scanConfig.imagePadding = 8
        scanConfig.cornerStyle = .medium
        scanButton.configuration = scanConfig
        scanButton.addTarget(self, action: #selector(scanTapped), for: .touchUpInside)

        // Added scanButton to the top of the stack
        let stack = UIStackView(arrangedSubviews: [scanButton, nameField, amountField, categoryButton, dateStack])
        stack.axis = .vertical
        stack.spacing = 16
        stack.distribution = .fillEqually

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        for item in [nameField, amountField] {
            item.backgroundColor = .secondarySystemGroupedBackground
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
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // Increased height slightly to accommodate the new button
            stack.heightAnchor.constraint(equalToConstant: 280),
        ])
    }

    private func setupCategoryMenu() {
        categoryButton.setTitle(selectedCategory, for: .normal)
        let menuActions = categories.map { category in
            UIAction(title: category) { [weak self] action in
                self?.selectedCategory = action.title
                self?.categoryButton.setTitle(action.title, for: .normal)
            }
        }
        categoryButton.menu = UIMenu(title: "Select Category", children: menuActions)
        categoryButton.showsMenuAsPrimaryAction = true
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

            // ⭐️ NEW: Feed the image into the Vision network!
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
                    print("🧠 AI categorized '\(merchantName)' as '\(category)' based on keyword: '\(keyword)'")
                    return category
                }
            }
        }

        // If the AI has no idea, safely fallback to the default
        print("🧠 AI could not classify '\(merchantName)', defaulting to Miscellaneous.")
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

        let newExpense = Expense(name: name, amount: amount, category: selectedCategory, date: datePicker.date)
        delegate?.didAddExpense(newExpense)
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}
