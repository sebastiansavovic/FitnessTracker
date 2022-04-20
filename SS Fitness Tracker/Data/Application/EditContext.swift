//
//  EditContext.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/7/21.
//

import Foundation
import UIKit

class EditContext<T:Contract>{
    private var editingLines:[IndexPath: EditLine<T>] = [IndexPath: EditLine<T>]()
    
    func isEditingAtRow(index: IndexPath) -> Bool {
        if let _ = self.editingLines[index] {
            return true
        }
        return false
    }
    func isEmpty() -> Bool {
        return self.editingLines.isEmpty
    }
    func getEditValueAtRow(index: IndexPath) -> T? {
        if let editPair = self.editingLines[index] {
            return editPair.newValue
        }
        return nil
    }
    func clear() {
        self.editingLines = [IndexPath: EditLine<T>]()
    }
    
    func removeFromContext(id: IndexPath) {
        if let _ = self.editingLines[id] {
            self.editingLines.removeValue(forKey: id)
        }
    }
    func getAllUnEditedIndexes() -> [IndexPath] {
        return self.editingLines.filter({
            $0.value.originalValue != nil &&
                $0.value.newValue == nil
        }).map({
            $0.key
        })
    }
    func getAllNewItems() -> [(IndexPath, T)] {
        return self.editingLines.filter({
            $0.value.newValue != nil &&
                $0.value.originalValue == nil
        }).map({
            ($0.key, $0.value.newValue!)
        })
    }
    func getAllEditedItems() -> [(IndexPath, T)] {
        return self.editingLines.filter({
            $0.value.newValue != nil &&
                $0.value.originalValue != nil
        }).map({
            ($0.key, $0.value.newValue!)
        })
    }
    func applyEditByPrimaryKey(id: UUID, newValue:T?) {
        if let value = self.editingLines.first(where: {
            $0.value.id == id
        }) {
            value.value.newValue = newValue
            self.editingLines[value.key] = value.value
            MyLog.debug("Value was changed")
        }
        else {
            MyLog.debug("Value was not changed")
        }
    }
    func applyNew(index: IndexPath, newValue:T, id:UUID) {
        self.editingLines[index] = EditLine<T>(originalValue: nil, newValue: newValue, id: id)
    }
    func applyNewEdit(index: IndexPath, oldValue:T, newValue:T?, id: UUID) {
        var editPair = EditLine<T>(originalValue: nil, newValue: nil, id: UUID())
        if let currentEdit = self.editingLines[index] {
            editPair = currentEdit
            editPair.newValue = newValue
        }
        else {
            editPair = EditLine<T>(originalValue: oldValue, newValue: newValue, id: id)
        }
        self.editingLines[index] = editPair
    }
}

fileprivate class EditLine<T:Contract>{
    let originalValue:T?
    var newValue:T?
    let id:UUID
    init(originalValue:T?, newValue:T?, id:UUID) {
        self.originalValue = originalValue
        self.newValue = newValue
        self.id = id
    }
}
