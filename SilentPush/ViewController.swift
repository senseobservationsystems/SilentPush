import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var hasContentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var clearButton: UIBarButtonItem!
    @IBOutlet weak var allocMemoryButton: UIBarButtonItem!

    var viewModel: ViewModel! {
        didSet {
            viewModel.addUpdateHandler { _ in
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
        allocMemoryButton?.enabled = viewModel.allocMemoryButtonEnabled
        allocMemoryButton?.title = viewModel.allocMemoryButtonTitle
        tableView?.reloadData()
    }

    @IBAction func deleteAllData(sender: UIBarButtonItem) {
        viewModel.deleteAllData()
    }

    @IBAction func fillMemory(sender: UIBarButtonItem) {
        if viewModel.hasAllocatedDummyMemory {
            viewModel.freeDummyMemory()
        } else {
            let alert = UIAlertController(title: "Allocate some dummy memory", message: "This allocates a ton of memory. Do this to make it much more likely that the OS will kill the app while it is in the background. You can use Activity Monitor in Instruments to check when the app gets killed without having the debugger attached.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Proceed", style: .Default) { [weak self] _ in self?.viewModel.allocateDummyMemory() })
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        }
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.pushNotifications.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let event = viewModel.pushNotifications[indexPath.row]
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

extension ViewController: UITableViewDelegate {}
