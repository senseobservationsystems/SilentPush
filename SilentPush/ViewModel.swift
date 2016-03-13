class ViewModel {

    init(store: UserDefaultsDataStore<SerializableArray<BackgroundActivity>>) {
        eventsStore = store
        eventsStore.addUpdateHandler { [weak self] store in
            guard let `self` = self else {
                return
            }
            for callback in self.updateHandlers {
                callback(self)
            }
        }
    }

    var eventsStore: UserDefaultsDataStore<SerializableArray<BackgroundActivity>>
    var pushNotifications: [BackgroundActivity] { return eventsStore.value.elements }

    var emptyStateViewHidden: Bool { return !eventsStore.value.isEmpty }
    var hasContentViewHidden: Bool { return eventsStore.value.isEmpty }
    var clearButtonEnabled: Bool { return !eventsStore.value.isEmpty }

    func deleteAllData() {
        eventsStore.value = []
    }

    private var updateHandlers: [ViewModel -> ()] = []

    func addUpdateHandler(callback: ViewModel -> ()) {
        updateHandlers.append(callback)
    }
}
