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

        // Ask for permission to display badge numbers on the app icon.
        // This is not needed to receive silent push notifications.
        // We use the badge to signal when the app got activated in the background upon receipt of an event.
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Badge], categories: nil)
        application.registerUserNotificationSettings(notificationSettings)

        // Register to receive (silent) push notifications
        application.registerForRemoteNotifications()

        numberOfEventsReceivedWhileInBackgroundStore.addUpdateHandler { store in
            // Update the app icon badge when a we receive an event while in the background.
            dispatch_async(dispatch_get_main_queue()) {
                UIApplication.sharedApplication().applicationIconBadgeNumber = store.value
            }
        }

        return true
    }

    func applicationDidBecomeActive(application: UIApplication) {
        numberOfEventsReceivedWhileInBackgroundStore.value = 0
    }

    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        print("\(__FUNCTION__): \(notificationSettings)")
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print("\(__FUNCTION__): \(deviceToken)")
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("\(__FUNCTION__): \(error)")
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print("\(__FUNCTION__): \(userInfo)")

        if application.applicationState != .Active {
            numberOfEventsReceivedWhileInBackgroundStore.value += 1
        }

        let event = BackgroundActivity.PushNotification(receivedAt: NSDate(), applicationStateOnReceipt: application.applicationState, payload: userInfo)
        eventsStore.value.elements.insert(event, atIndex: 0)

        // Always tell the OS there has been new data so we get called again.
        completionHandler(.NewData)
    }

    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print("\(__FUNCTION__)")

        let event = BackgroundActivity.BackgroundAppRefresh(receivedAt: NSDate())
        eventsStore.value.elements.insert(event, atIndex: 0)

        // Always tell the OS there has been new data so we get called again.
        completionHandler(.NewData)
    }
}
