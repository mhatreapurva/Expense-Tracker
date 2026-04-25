import UIKit

class SubscriptionsViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Subscriptions"
        view.backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "subCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SubscriptionManager.shared.subscriptions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "subCell", for: indexPath)
        let sub = SubscriptionManager.shared.subscriptions[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = sub.name
        
        let currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "$"
        let formattedAmount = String(format: "\(currencySymbol)%.2f", sub.amount)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let nextDateStr = formatter.string(from: sub.nextDueDate)
        
        content.secondaryText = "\(formattedAmount) • \(sub.interval.rawValue) • Next: \(nextDateStr)"
        content.image = UIImage(systemName: "repeat")
        content.imageProperties.tintColor = .systemBlue
        
        cell.contentConfiguration = content
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let sub = SubscriptionManager.shared.subscriptions[indexPath.row]
            SubscriptionManager.shared.removeSubscription(id: sub.id)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
