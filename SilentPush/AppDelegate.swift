import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    /// Stores the sequence of "background acitivy events" our app received. Possible event types are:
    /// - Push notifications (regardless whether received while app is in the background or foreground)
    /// - Background fetch wakeups
    let eventsStore = UserDefaultsDataStore<SerializableArray<BackgroundActivity>>(key: "backgroundActivityEvents", defaultValue: [])

    /// Stores the number of background activity events our app received while it was in the background.
    /// Should be reset to 0 the next time the app comes into the foreground.
    let numberOfEventsReceivedWhileInBackgroundStore = UserDefaultsDataStore<Int>(key: "eventsReceivedWhileInBackground", defaultValue: 0)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        guard
            let tabBarController = window?.rootViewController as? UITabBarController,
            let tabBarChildViewControllers = tabBarController.viewControllers where tabBarChildViewControllers.count >= 2,
            let eventsTabNavController = tabBarChildViewControllers[0] as? UINavigationController,
            let eventsViewController = eventsTabNavController.viewControllers.first as? EventsViewController,
            let fillMemoryTabNavController = tabBarChildViewControllers[1] as? UINavigationController,
            let fillMemoryViewController = fillMemoryTabNavController.viewControllers.first as? FillMemoryViewController
        else {
            preconditionFailure("View controllers not found")
        }

        eventsViewController.viewModel = EventsViewModel(store: eventsStore)
        fillMemoryViewController.viewModel = FillMemoryViewModel()

        // Tell the OS to wake us in the background as often as possible.
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)

        // Ask for permission to display alerts and badge numbers on the app icon.
        // This is not needed to receive silent push notifications.
        // We use the badge and alerts to signal when the app got activated in the background upon receipt of an event.
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge], categories: nil)
        application.registerUserNotificationSettings(notificationSettings)

        // Register to receive (silent) push notifications
        application.registerForRemoteNotifications()

        return true
    }

    func applicationDidBecomeActive(application: UIApplication) {
        numberOfEventsReceivedWhileInBackgroundStore.value = 0
        application.applicationIconBadgeNumber = numberOfEventsReceivedWhileInBackgroundStore.value
    }

    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        print("\(#function): \(notificationSettings)")
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print("\(#function): \(deviceToken)")
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("\(#function): \(error)")
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print("\(#function): \(userInfo)")

        let event = BackgroundActivity.PushNotification(receivedAt: NSDate(), applicationStateOnReceipt: application.applicationState, payload: userInfo)
        eventsStore.value.elements.insert(event, atIndex: 0)
        if application.applicationState != .Active {
            numberOfEventsReceivedWhileInBackgroundStore.value += 1
            let localNotification = UILocalNotification(backgroundActivity: event, badgeNumber: numberOfEventsReceivedWhileInBackgroundStore.value)
            application.scheduleLocalNotification(localNotification)
        }

        // Always tell the OS there has been new data so we get called again.
        completionHandler(.NewData)
    }

    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print("\(#function)")

        let event = BackgroundActivity.BackgroundAppRefresh(receivedAt: NSDate())
        eventsStore.value.elements.insert(event, atIndex: 0)
        if application.applicationState != .Active {
            numberOfEventsReceivedWhileInBackgroundStore.value += 1
            let localNotification = UILocalNotification(backgroundActivity: event, badgeNumber: numberOfEventsReceivedWhileInBackgroundStore.value)
            application.scheduleLocalNotification(localNotification)
        }

        // Always tell the OS there has been new data so we get called again.
        completionHandler(.NewData)
    }

    func applicationDidReceiveMemoryWarning(application: UIApplication) {
        print("\(#function)")
    }

}

extension UILocalNotification {
    convenience init(backgroundActivity: BackgroundActivity, badgeNumber: Int = 0) {
        self.init()
        applicationIconBadgeNumber = badgeNumber
        switch backgroundActivity {
        case .PushNotification(receivedAt: _, applicationStateOnReceipt: _, payload: let payload):
            alertBody = "Push Notification: \(payload)"
        case .BackgroundAppRefresh(receivedAt: _):
            alertBody = "Background Fetch"
        }
    }
}
