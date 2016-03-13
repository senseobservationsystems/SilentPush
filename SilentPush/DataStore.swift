import Foundation

protocol Storable {}

protocol DataStore {
    typealias Element: Storable

    var value: Element { get set }

    func addUpdateHandler(callback: Self -> ())
}

class UserDefaultsDataStore<Element: PropertyListSerializable>: DataStore {

    let key: String
    private let defaultValue: Element
    private let defaults = NSUserDefaults()

    init(key: String, defaultValue: Element) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var value: Element {
        get {
            guard let plist = defaults.objectForKey(key) else {
                return defaultValue
            }
            guard let v = Element.init(propertyList: plist) else {
                preconditionFailure("Invalid property list: \(plist)")
            }
            return v
        }

        set {
            let plist = newValue.propertyListRepresentation()
            defaults.setObject(plist, forKey: key)
            for callback in updateHandlers {
                callback(self)
            }
        }
    }

    private var updateHandlers: [UserDefaultsDataStore<Element> -> ()] = []

    func addUpdateHandler(callback: UserDefaultsDataStore<Element> -> ()) {
        updateHandlers.append(callback)
    }

}
