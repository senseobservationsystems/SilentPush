import UIKit

class ViewController: UIViewController {

    var pushNotifications: [PushNotification] = [] {
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                [weak self] in
                guard let `self` = self else {
                    return
                }
                switch self.pushNotifications.count {
                case 0:
                    self.emptyStateView?.hidden = false
                    self.hasContentView?.hidden = true
                    self.clearButton?.enabled = false
                default:
                    self.emptyStateView?.hidden = true
                    self.hasContentView?.hidden = false
                    self.clearButton?.enabled = true
                }
                self.tableView?.reloadData()
            }
        }
    }

    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var hasContentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var clearButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func deleteAllData(sender: UIBarButtonItem) {
        pushNotifications.removeAll()
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pushNotifications.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MyCell", forIndexPath: indexPath)
        let notification = pushNotifications[indexPath.row]
        cell.textLabel?.text = String(notification)
        return cell
    }
}

extension ViewController: UITableViewDelegate {}
