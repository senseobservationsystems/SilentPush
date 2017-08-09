import UIKit

class EventsViewController: UIViewController {

    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var hasContentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var clearButton: UIBarButtonItem!
    @IBOutlet weak var exportButton: UIBarButtonItem!

    var viewModel: EventsViewModel! {
        didSet {
            viewModel.addObserver { _ in
                DispatchQueue.main.async() { [weak self] in
                    self?.updateUI()
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100.0

        updateUI()
    }

    func updateUI() {
        emptyStateView?.isHidden = viewModel.emptyStateViewHidden
        hasContentView?.isHidden = viewModel.hasContentViewHidden
        clearButton?.isEnabled = viewModel.clearButtonEnabled
        tableView?.reloadData()
    }

    @IBAction func clearList(sender: UIBarButtonItem) {
        viewModel.deleteAllData()
    }
    
    @IBAction func exportList(sender: UIBarButtonItem) {
        let eventsString = [viewModel.events.debugDescription]
        let activityVC = UIActivityViewController(activityItems: eventsString,
                                                  applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
    }
}

extension EventsViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = viewModel.events[indexPath.row]
        switch event {
        case .PushNotification(receivedAt: let receivedAt, applicationStateOnReceipt: let applicationState, payload: let payload):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "PushNotificationCell", for: indexPath) as? PushNotificationCell else {
                preconditionFailure("Expected a PushNotificationCell")
            }
            cell.dateLabel.text = DateFormatter.localizedString(from: receivedAt, dateStyle: .medium, timeStyle: .medium)
            cell.applicationStateLabel.text = "Received in app state: \(applicationState)"
            cell.payloadLabel.text = String(describing: payload)
            return cell
        case .BackgroundAppRefresh(receivedAt: let receivedAt):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "BackgroundAppRefreshCell", for: indexPath) as? BackgroundAppRefreshCell else {
                preconditionFailure("Expected a BackgroundAppRefreshCell")
            }
            cell.dateLabel.text = DateFormatter.localizedString(from: receivedAt, dateStyle: .medium, timeStyle: .medium)
            return cell
        }
    }
}

extension EventsViewController: UITableViewDelegate {}
