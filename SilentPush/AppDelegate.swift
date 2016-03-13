import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var rootViewController: ViewController {
        guard let
            navigationController = window?.rootViewController as? UINavigationController,
            topViewController = navigationController.viewControllers.first as? ViewController
        else {
            preconditionFailure("No view controller found")
        }
        return topViewController
    }

    let pushNotificationsStore = UserDefaultsDataStore<SerializableArray<PushNotification>>(key: "receivedPushNotifications", defaultValue: [])
    let numberOfNotificationsReceivedWhileInBackgroundStore = UserDefaultsDataStore<Int>(key: "pushNotificationsReceivedWhileInBackground", defaultValue: 0)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Ask for permission to display badge numbers on the app icon.
        // This is not needed to receive silent push notifications.
        // We use the badge to signal when the app got activated in the background upon receipt of a
        // push notification.
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Badge], categories: nil)
        application.registerUserNotificationSettings(notificationSettings)

        // Register to receive (silent) push notifications
        application.registerForRemoteNotifications()

        rootViewController.pushNotifications = pushNotificationsStore.value.elements
        pushNotificationsStore.addUpdateHandler { [unowned self] store in
            self.rootViewController.pushNotifications = store.value.elements
        }

        numberOfNotificationsReceivedWhileInBackgroundStore.addUpdateHandler { store in
            // Update the app icon badge when a we receive a push notification while in the background.
            dispatch_async(dispatch_get_main_queue()) {
                UIApplication.sharedApplication().applicationIconBadgeNumber = store.value
            }
        }

        return true
    }

    func applicationDidBecomeActive(application: UIApplication) {
        numberOfNotificationsReceivedWhileInBackgroundStore.value = 0
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

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        print("\(__FUNCTION__): \(notification)")
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {

        print("\(__FUNCTION__): \(userInfo)")

        if application.applicationState != .Active {
            numberOfNotificationsReceivedWhileInBackgroundStore.value += 1
        }

        let pushNotification = PushNotification(receivedAt: NSDate(), payload: userInfo)
        pushNotificationsStore.value.elements.insert(pushNotification, atIndex: 0)

        completionHandler(.NewData)
    }

}
