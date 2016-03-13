class ViewModel {

    init(store: UserDefaultsDataStore<SerializableArray<PushNotification>>) {
        pushNotificationsStore = store
        pushNotificationsStore.addUpdateHandler { [weak self] store in
            guard let `self` = self else {
                return
            }
            for callback in self.updateHandlers {
                callback(self)
            }
        }
    }

    var pushNotificationsStore: UserDefaultsDataStore<SerializableArray<PushNotification>>
    var pushNotifications: [PushNotification] { return pushNotificationsStore.value.elements }

    var emptyStateViewHidden: Bool { return !pushNotificationsStore.value.isEmpty }
    var hasContentViewHidden: Bool { return pushNotificationsStore.value.isEmpty }
    var clearButtonEnabled: Bool { return !pushNotificationsStore.value.isEmpty }

    func deleteAllData() {
        pushNotificationsStore.value = []
    }

    private var updateHandlers: [ViewModel -> ()] = []

    func addUpdateHandler(callback: ViewModel -> ()) {
        updateHandlers.append(callback)
    }
}
