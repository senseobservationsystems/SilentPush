import Foundation
import UIKit

protocol PropertyListSerializable: Storable {
    init?(propertyList: AnyObject)
    func propertyListRepresentation() -> AnyObject
}

struct PushNotification {
    let receivedAt: NSDate
    let applicationStateOnReceipt: UIApplicationState
    let payload: [NSObject : AnyObject]
}

extension PushNotification: CustomStringConvertible {
    var description: String {
        return "PushNotification: \(receivedAt) – payload: \(payload)"
    }
}

extension PushNotification: PropertyListSerializable {
    init?(propertyList: AnyObject) {
        guard let
            dict = propertyList as? [String : AnyObject],
            receivedAt = dict["receivedAt"] as? NSDate,
            applicationStateRawValue = dict["applicationState"] as? Int,
            applicationState = UIApplicationState(rawValue: applicationStateRawValue),
            payload = dict["payload"] as? [NSObject : AnyObject]
        else {
                return nil
        }
        self.receivedAt = receivedAt
        self.applicationStateOnReceipt = applicationState
        self.payload = payload
    }

    func propertyListRepresentation() -> AnyObject {
        return [
            "receivedAt": receivedAt,
            "applicationState": applicationStateOnReceipt.rawValue,
            "payload": payload
        ]
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
