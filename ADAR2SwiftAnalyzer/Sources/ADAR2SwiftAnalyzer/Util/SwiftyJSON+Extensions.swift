//
//  SwiftyJSON+Extensions.swift
//
//
//  Created by Alex Frankiv on 17.01.2024.
//

import Foundation
import SwiftyJSON

extension JSON {

    func firstChild(havingValue value: String, forKey key: String) -> JSON? {
        let equalityAction: (JSON) -> Bool = { node in
            return self[key].stringValue == value
        }

        if equalityAction(self) {
            return self
        } else if let dictValues = self.dictionary?.values {
            for node in dictValues {
                if let firstChild = node.firstChild(havingValue: value, forKey: key) {
                    return firstChild
                }
            }
        } else if let arrayValues = self.array {
            for node in arrayValues {
                if let firstChild = node.firstChild(havingValue: value, forKey: key) {
                    return firstChild
                }
            }
        }
        return nil
    }
}
