import UIKit

class EventsViewController: UIViewController {

    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var hasContentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var clearButton: UIBarButtonItem!

    var viewModel: EventsViewModel! {
        didSet {
            viewModel.addObserver { _ in
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
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
        emptyStateView?.hidden = viewModel.emptyStateViewHidden
        hasContentView?.hidden = viewModel.hasContentViewHidden
        clearButton?.enabled = viewModel.clearButtonEnabled
        tableView?.reloadData()
    }

    @IBAction func clearList(sender: UIBarButtonItem) {
        viewModel.deleteAllData()
    }

}

extension EventsViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.events.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let event = viewModel.events[indexPath.row]
        switch event {
        case .PushNotification(receivedAt: let receivedAt, applicationStateOnReceipt: let applicationState, payload: let payload):
            guard let cell = tableView.dequeueReusableCellWithIdentifier("PushNotificationCell", forIndexPath: indexPath) as? PushNotificationCell else {
                preconditionFailure("Expected a PushNotificationCell")
            }
            cell.dateLabel.text = NSDateFormatter.localizedStringFromDate(receivedAt, dateStyle: .MediumStyle, timeStyle: .MediumStyle)
            cell.applicationStateLabel.text = "Received in app state: \(applicationState)"
            cell.payloadLabel.text = String(payload)
            return cell
        case .BackgroundAppRefresh(receivedAt: let receivedAt):
            guard let cell = tableView.dequeueReusableCellWithIdentifier("BackgroundAppRefreshCell", forIndexPath: indexPath) as? BackgroundAppRefreshCell else {
                preconditionFailure("Expected a BackgroundAppRefreshCell")
            }
            cell.dateLabel.text = NSDateFormatter.localizedStringFromDate(receivedAt, dateStyle: .MediumStyle, timeStyle: .MediumStyle)
            return cell
        }
    }
}

extension EventsViewController: UITableViewDelegate {}
