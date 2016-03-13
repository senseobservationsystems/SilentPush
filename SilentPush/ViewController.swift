import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var hasContentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var clearButton: UIBarButtonItem!

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
        updateUI()
    }

    func updateUI() {
        emptyStateView?.hidden = viewModel.emptyStateViewHidden
        hasContentView?.hidden = viewModel.hasContentViewHidden
        clearButton?.enabled = viewModel.clearButtonEnabled
        tableView?.reloadData()
    }

    @IBAction func deleteAllData(sender: UIBarButtonItem) {
        viewModel.deleteAllData()
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
        let cell = tableView.dequeueReusableCellWithIdentifier("MyCell", forIndexPath: indexPath)
        let notification = viewModel.pushNotifications[indexPath.row]
        cell.textLabel?.text = String(notification)
        return cell
    }
}

extension ViewController: UITableViewDelegate {}
