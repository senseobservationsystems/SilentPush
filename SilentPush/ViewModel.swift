class ViewModel {

    init(store: UserDefaultsDataStore<SerializableArray<BackgroundActivity>>) {
        eventsStore = store
        eventsStore.addUpdateHandler { [weak self] store in
            guard let `self` = self else {
                return
            }
            self.notifyUpdateHandlers()
        }
    }

    var eventsStore: UserDefaultsDataStore<SerializableArray<BackgroundActivity>>
    var pushNotifications: [BackgroundActivity] { return eventsStore.value.elements }

    var emptyStateViewHidden: Bool { return !eventsStore.value.isEmpty }
    var hasContentViewHidden: Bool { return eventsStore.value.isEmpty }
    var clearButtonEnabled: Bool { return !eventsStore.value.isEmpty }
    var allocMemoryButtonEnabled = true
    var allocMemoryButtonTitle: String { return hasAllocatedDummyMemory ? "Free Memory" : "Fill Memory" }

    func deleteAllData() {
        eventsStore.value = []
    }

    private var dummyMemory: [Int64]?

    var hasAllocatedDummyMemory: Bool {
        return dummyMemory != nil
    }

    /// Allocates a ton of memory. Useful if you want the OS to kill the app while it is in the
    /// background. You can use Activity Monitor in Instruments to check when the app gets killed
    /// without the debugger attached.
    func allocateDummyMemory() {
        dummyMemory = Array(count: 50_000_000, repeatedValue: 0)
        notifyUpdateHandlers()
    }

    func freeDummyMemory() {
        dummyMemory = nil
        notifyUpdateHandlers()
    }

    private var updateHandlers: [ViewModel -> ()] = []

    func addUpdateHandler(callback: ViewModel -> ()) {
        updateHandlers.append(callback)
    }

    private func notifyUpdateHandlers() {
        for callback in updateHandlers {
            callback(self)
        }
    }
}
