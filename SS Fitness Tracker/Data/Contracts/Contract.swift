//
//  Contract.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/3/21.
//

import Foundation

public protocol Contract {
    associatedtype T: Contract
    func getPrimaryId() -> UUID
    // MARK: clones replaces the parent id with the new id, if object does not have a parent id, it will just clone
    func cloneShallowWithNewParentId(id: UUID) -> T
}

