import Foundation
import UIKit

protocol PropertyListSerializable: Storable {
    init?(propertyList: AnyObject)
    func propertyListRepresentation() -> AnyObject
}

enum BackgroundActivity {
    case PushNotification(receivedAt: NSDate, applicationStateOnReceipt: UIApplicationState, payload: [NSObject : AnyObject])
    case BackgroundAppRefresh(receivedAt: NSDate)
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
    init?(propertyList: AnyObject) {
        guard let
            dict = propertyList as? [String : AnyObject],
            type = dict["type"] as? String
        else {
            return nil
        }
        switch type {
            case "PushNotification":
                guard let
                    receivedAt = dict["receivedAt"] as? NSDate,
                    applicationStatePropertyList = dict["applicationState"],
                    applicationState = UIApplicationState(propertyList: applicationStatePropertyList),
                    payload = dict["payload"] as? [NSObject : AnyObject]
                else {
                    return nil
                }
                self = .PushNotification(receivedAt: receivedAt, applicationStateOnReceipt: applicationState, payload: payload)
            case "BackgroundAppRefresh":
                guard let receivedAt = dict["receivedAt"] as? NSDate else {
                    return nil
                }
                self = .BackgroundAppRefresh(receivedAt: receivedAt)
            default:
                fatalError("Unknown event type: \(type)")
        }
    }

    func propertyListRepresentation() -> AnyObject {
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
    init?(propertyList: AnyObject) {
        guard let rawValue = propertyList as? Int else {
            return nil
        }
        self.init(rawValue: rawValue)
    }

    func propertyListRepresentation() -> AnyObject {
        return self.rawValue
    }
}

extension UIApplicationState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .Active: return "active"
        case .Inactive: return "inactive"
        case .Background: return "background"
        }
    }
}

extension Int: PropertyListSerializable {
    init?(propertyList: AnyObject) {
        guard let value = propertyList as? Int else {
            return nil
        }
        self = value
    }

    func propertyListRepresentation() -> AnyObject {
        return self
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

extension SerializableArray: CollectionType {
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
    init?(propertyList: AnyObject) {
        guard let plistElements = propertyList as? [AnyObject] else {
            return nil
        }
        let deserializedElements = plistElements.flatMap { element in
            Element(propertyList: element)
        }
        self.init(deserializedElements)
    }

    func propertyListRepresentation() -> AnyObject {
        return self.map { $0.propertyListRepresentation() }
    }
}
