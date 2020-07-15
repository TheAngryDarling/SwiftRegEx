//
//  String+RegularExpression.swift
//  RegEx
//
//  Created by Tyler Anger on 2017-08-31.
//  Copyright © 2019 Tyler Anger. All rights reserved.
//

import Foundation

public extension String {
    
    /// The Full range of the string from startIndex..<endIndex
    internal var _regExFullRange: Range<String.Index> { return Range<String.Index>(uncheckedBounds: (lower: self.startIndex, upper: self.endIndex)) }
    
    /// Returns an array containing all the matches of the regular expression in the string.
    /// - Parameter pattern: The pattern to search for
    /// - Parameter matchingOptions: The matching options to use. See RegEx.MatchingOptions for possible values.
    /// - Parameter range: The range of the string to search.
    /// - Returns: An array of RegEx.Match objects. Each result gives the overall matched range via its range property, and the range of each individual capture group via its range(at:) method. Nil is returned if one of the capture groups did not participate in this particular match.
    func match(pattern: RegEx,
               matchingOptions: RegEx.MatchingOptions = [],
               range: Range<String.Index>? = nil) -> [RegEx.Match]  {
        return pattern.matches(in: self, options: matchingOptions, range: range ?? self._regExFullRange)
    }
    /// Returns an array containing all the matches of the regular expression in the string.
    /// - Parameter pattern: The pattern to search for
    /// - Parameter options: The regular expression options that are applied to the expression during matching. See RegEx.Options for possible values.
    /// - Parameter matchingOptions: The matching options to use. See RegEx.MatchingOptions for possible values.
    /// - Parameter range: The range of the string to search.
    /// - Returns: An array of RegEx.Match objects. Each result gives the overall matched range via its range property, and the range of each individual capture group via its range(at:) method. Nil is returned if one of the capture groups did not participate in this particular match.
    func match(pattern: String,
                      options: RegEx.Options = [],
                      matchingOptions: RegEx.MatchingOptions = [],
                      range: Range<String.Index>? = nil) throws -> [RegEx.Match]  {
        
        let regx: RegEx = try RegEx(pattern: pattern, options: options)
        
        return self.match(pattern: regx, matchingOptions: matchingOptions, range: range)

    }
    
    /// Returns the first match of the regular expression within the specified range of the string.
    /// - Parameter pattern: The pattern to search for
    /// - Parameter matchingOptions: The matching options to use. See RegEx.MatchingOptions for possible values.
    /// - Parameter range: The range of the string to search.
    /// - Returns: An RegEx.Match object. This result gives the overall matched range via its range property, and the range of each individual capture group via its range(at:) method. Nil is returned if one of the capture groups did not participate in this particular match.
    func firstMatch(pattern: RegEx,
                    matchingOptions: RegEx.MatchingOptions = [],
                    range: Range<String.Index>? = nil) -> RegEx.Match? {
        
        return pattern.firstMatch(in: self, options: matchingOptions, range: range ?? self._regExFullRange)
    }
    
    /// Returns the first match of the regular expression within the specified range of the string.
    /// - Parameter pattern: The pattern to search for
    /// - Parameter options: The regular expression options that are applied to the expression during matching. See RegEx.Options for possible values.
    /// - Parameter matchingOptions: The matching options to use. See RegEx.MatchingOptions for possible values.
    /// - Parameter range: The range of the string to search.
    /// - Returns: An RegEx.Match object. This result gives the overall matched range via its range property, and the range of each individual capture group via its range(at:) method. Nil is returned if one of the capture groups did not participate in this particular match.
    func firstMatch(pattern: String,
                           options: RegEx.Options = [],
                           matchingOptions: RegEx.MatchingOptions = [],
                           range: Range<String.Index>? = nil) throws -> RegEx.Match? {
        
        let regx: RegEx = try RegEx(pattern: pattern, options: options)
        
        return self.firstMatch(pattern: regx, matchingOptions: matchingOptions, range: range)
    }
}
