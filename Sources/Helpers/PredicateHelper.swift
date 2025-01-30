//
//  PredicateHelper.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 30/01/25.
//

import Foundation

public struct PredicateHelper {
  
  /// Predicate for exact match of a string value
  public static func equals<T>(_ key: String, value: T) -> NSPredicate {
    return NSPredicate(format: "%K == %@", key, value as! CVarArg)
  }
  
  /// Predicate for checking if a number is greater than or equal to a given value
  public static func greaterThanOrEqual<T: Numeric>(_ key: String, value: T) -> NSPredicate {
    return NSPredicate(format: "%K >= %@", key, NSNumber(value: Double(truncating: value as! NSNumber)))
  }
  
  /// Predicate for checking if a number is less than or equal to a given value
  public static func lessThanOrEqual<T: Numeric>(_ key: String, value: T) -> NSPredicate {
    return NSPredicate(format: "%K <= %@", key, NSNumber(value: Double(truncating: value as! NSNumber)))
  }
  
  /// Predicate for checking if a string contains a certain value (case insensitive)
  public static func contains(_ key: String, value: String) -> NSPredicate {
    return NSPredicate(format: "%K CONTAINS[c] %@", key, value)
  }
  
  /// Predicate for filtering boolean values
  public static func isTrue(_ key: String) -> NSPredicate {
    return NSPredicate(format: "%K == %@", key, NSNumber(value: true))
  }
  
  public static func isFalse(_ key: String) -> NSPredicate {
    return NSPredicate(format: "%K == %@", key, NSNumber(value: false))
  }
  
  /// Predicate for filtering records with date greater than or equal to a given date
  public static func dateAfterOrEqual(_ key: String, value: Date) -> NSPredicate {
    return NSPredicate(format: "%K >= %@", key, value as CVarArg)
  }
  
  /// Predicate for filtering records with date less than or equal to a given date
  public static func dateBeforeOrEqual(_ key: String, value: Date) -> NSPredicate {
    return NSPredicate(format: "%K <= %@", key, value as CVarArg)
  }
  
  /// Combines two predicates using AND
  public static func and(_ predicates: NSPredicate...) -> NSPredicate {
    return NSCompoundPredicate(type: .and, subpredicates: predicates)
  }
  
  /// Combines two predicates using OR
  public static func or(_ predicates: NSPredicate...) -> NSPredicate {
    return NSCompoundPredicate(type: .or, subpredicates: predicates)
  }
}
