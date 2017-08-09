protocol Observable {
    func addObserver(callback: @escaping (Self) -> ())
    func notifyObservers()
}

final class EventsViewModel {

    init(store: UserDefaultsDataStore<SerializableArray<BackgroundActivity>>) {
        eventsStore = store
        eventsStore.addUpdateHandler { [weak self] store in
            guard let `self` = self else {
                return
            }
            self.notifyObservers()
        }
    }

    var eventsStore: UserDefaultsDataStore<SerializableArray<BackgroundActivity>>
    var events: [BackgroundActivity] { return eventsStore.value.elements }

    var emptyStateViewHidden: Bool { return !eventsStore.value.isEmpty }
    var hasContentViewHidden: Bool { return !eventsStore.value.isEmpty }
    var clearButtonEnabled: Bool { return !eventsStore.value.isEmpty }

    func deleteAllData() {
        eventsStore.value = []
    }

    fileprivate var observers: [(EventsViewModel) -> ()] = []
}

extension EventsViewModel: Observable {
    func addObserver(callback: @escaping (EventsViewModel) -> ()) {
        observers.append(callback)
    }
    
    func notifyObservers() {
        for callback in observers {
            callback(self)
        }
    }
}
