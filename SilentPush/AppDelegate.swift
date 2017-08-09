import UIKit
import UserNotifications

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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        guard
            let tabBarController = window?.rootViewController as? UITabBarController,
            let tabBarChildViewControllers = tabBarController.viewControllers, tabBarChildViewControllers.count >= 2,
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
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge], completionHandler: { (granted, error) in
            if (!granted){
                print("\(#function): No notifications? Well, that is fine.")
            }
            if (error != nil) {
                print("\(#function): \(error)")
            }
        })

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        numberOfEventsReceivedWhileInBackgroundStore.value = 0
        application.applicationIconBadgeNumber = numberOfEventsReceivedWhileInBackgroundStore.value
    }

    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        print("\(#function): \(notificationSettings)")
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print("\(#function): \(deviceToken)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("\(#function): \(error)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print("\(#function): \(userInfo)")

        let event = BackgroundActivity.PushNotification(receivedAt: Date(), applicationStateOnReceipt: application.applicationState, payload: userInfo)
        eventsStore.value.elements.insert(event, at: 0)
        
        self.sendNotification(event: event)

        // Always tell the OS there has been new data so we get called again.
        completionHandler(.newData)
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print("\(#function)")

        let event = BackgroundActivity.BackgroundAppRefresh(receivedAt: Date())
        eventsStore.value.elements.insert(event, at: 0)
        
        self.sendNotification(event: event)

        // Always tell the OS there has been new data so we get called again.
        completionHandler(.newData)
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        print("\(#function)")
    }
    
    func sendNotification(event: BackgroundActivity){
        self.numberOfEventsReceivedWhileInBackgroundStore.value += 1
        
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent(backgroundActivity: event, badgeNumber: self.numberOfEventsReceivedWhileInBackgroundStore.value)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "NotificationTest", content: content, trigger: trigger)
        
        center.add(request, withCompletionHandler: { (error) in
            if (error != nil) {
                print("\(#function):\(error)")
            }
        })
    }

}

extension UNMutableNotificationContent {
    convenience init(backgroundActivity: BackgroundActivity, badgeNumber: Int = 0) {
        self.init()
        badge = badgeNumber as NSNumber?
        switch backgroundActivity {
        case .PushNotification(receivedAt: _, applicationStateOnReceipt: _, payload: let payload):
            title = "PushNotification"
            body = "payload: \(payload)"
        case .BackgroundAppRefresh(receivedAt: _):
            title = "BackgroundAppRefresh"
            body = "BackgroundAppRefresh"
        }
    }
}
