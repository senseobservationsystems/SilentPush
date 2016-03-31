import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var rootViewController: ViewController {
        guard let
            navigationController = window?.rootViewController as? UINavigationController,
            topViewController = navigationController.viewControllers.first as? ViewController
        else {
            preconditionFailure("View controller not found")
        }
        return topViewController
    }

    /// Stores the sequence of "background acitivy events" our app received. Possible event types are:
    /// - Push notifications (regardless whether received while app is in the background or foreground)
    /// - Background fetch wakeups
    let eventsStore = UserDefaultsDataStore<SerializableArray<BackgroundActivity>>(key: "backgroundActivityEvents", defaultValue: [])

    /// Stores the number of background activity events our app received while it was in the background.
    /// Reset to 0 the next time the app comes into the foreground.
    let numberOfEventsReceivedWhileInBackgroundStore = UserDefaultsDataStore<Int>(key: "eventsReceivedWhileInBackground", defaultValue: 0)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        rootViewController.viewModel = ViewModel(store: eventsStore)

        // Tell the OS to wake us in the background as often as possible.
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)

        // Ask for permission to display badge numbers on the app icon.
        // This is not needed to receive silent push notifications.
        // We use the badge to signal when the app got activated in the background upon receipt of an event.
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
