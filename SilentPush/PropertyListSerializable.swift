import Foundation
import UIKit

protocol PropertyListSerializable: Storable {
    init?(propertyList: Any)
    func propertyListRepresentation() -> Any
}

enum BackgroundActivity {
    case PushNotification(receivedAt: Date, applicationStateOnReceipt: UIApplicationState, payload: [NSObject : Any])
    case BackgroundAppRefresh(receivedAt: Date)
}

extension BackgroundActivity: CustomStringConvertible {
    var description: String {
        switch self {
        case .PushNotification(receivedAt: let receivedAt, applicationStateOnReceipt: let applicationState, payload: let payload):
            return "PushNotification: \(receivedAt) – \(applicationState) – \(payload)"
        case .BackgroundAppRefresh(receivedAt: let receivedAt):
            return "Background App Refresh: \(receivedAt)"
        }
    }
}

extension BackgroundActivity: PropertyListSerializable {
    init?(propertyList: Any) {
        guard let
            dict = propertyList as? [String : Any],
            let type = dict["type"] as? String
        else {
            return nil
        }
        switch type {
            case "PushNotification":
                guard let
                    receivedAt = dict["receivedAt"] as? Date,
                    let applicationStatePropertyList = dict["applicationState"],
                    let applicationState = UIApplicationState(propertyList: applicationStatePropertyList),
                    let payload = dict["payload"] as? [NSObject : Any]
                else {
                    return nil
                }
                self = .PushNotification(receivedAt: receivedAt, applicationStateOnReceipt: applicationState, payload: payload)
            case "BackgroundAppRefresh":
                guard let receivedAt = dict["receivedAt"] as? Date else {
                    return nil
                }
                self = .BackgroundAppRefresh(receivedAt: receivedAt)
            default:
                fatalError("Unknown event type: \(type)")
        }
    }

    func propertyListRepresentation() -> Any {
        switch self {
        case .PushNotification(receivedAt: let receivedAt, applicationStateOnReceipt: let applicationState, payload: let payload):
            return [
                "type": "PushNotification",
                "receivedAt": receivedAt,
                "applicationState": applicationState.propertyListRepresentation(),
                "payload": payload
            ]
        case .BackgroundAppRefresh(receivedAt: let receivedAt):
            return [
                "type": "BackgroundAppRefresh",
                "receivedAt": receivedAt
            ]
        }
    }
}

extension UIApplicationState: PropertyListSerializable {
    init?(propertyList: Any) {
        guard let rawValue = propertyList as? Int else {
            return nil
        }
        self.init(rawValue: rawValue)
    }

    func propertyListRepresentation() -> Any {
        return self.rawValue
    }
}

extension UIApplicationState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .active: return "active"
        case .inactive: return "inactive"
        case .background: return "background"
        }
    }
}

extension Int: PropertyListSerializable {
    init?(propertyList: Any) {
        guard let value = propertyList as? Int else {
            return nil
        }
        self = value
    }

    func propertyListRepresentation() -> Any {
        return self as Any
    }
}

/// A wrapper for Array that conforms to PropertyListSerializable.
/// Elements must themselves conform to PropertyListSerializable.
///
/// This is a hack that is required because Swift 2.x doesn't support this:
///
///     extension Array: PropertyListSerializable where Element: PropertyListSerializable {
///         ...
///     }
///     // error: Extension of type 'Array' with constraints cannot have an inheritance clause
struct SerializableArray<Element: PropertyListSerializable> {
    var elements: [Element] = []

    init(_ elements: [Element]) {
        self.elements = elements
    }
}

extension SerializableArray: Collection {
    func index(after i: Int) -> Int {
        guard i != endIndex else {fatalError("Cannnot increment endIndex") }
        return i + 1
    }
    
    var startIndex: Int {
        return elements.startIndex
    }

    var endIndex: Int {
        return elements.endIndex
    }

    subscript(index: Int) -> Element {
        return elements[index]
    }
}

extension SerializableArray: ArrayLiteralConvertible {
    init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

extension SerializableArray: PropertyListSerializable {
    init?(propertyList: Any) {
        guard let plistElements = propertyList as? [Any] else {
            return nil
        }
        let deserializedElements = plistElements.flatMap { element in
            Element(propertyList: element)
        }
        self.init(deserializedElements)
    }

    func propertyListRepresentation() -> Any {
        return self.map { $0.propertyListRepresentation() }
    }
}
