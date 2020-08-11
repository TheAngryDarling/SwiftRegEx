//
//  RegEx.swift
//  RegEx
//
//  Created by Tyler Anger on 2017-08-31.
//  Copyright © 2019 Tyler Anger. All rights reserved.
//

import Foundation
/// An immutable representation of a compiled regular expression that you apply to Unicode strings.
public final class RegEx: NSObject, Codable, ExpressibleByStringLiteral {
    
    public enum Errors: Error {
        case parsedInvalidOptionFlags(String)
    }
    
    /// Parses pattern groups and keeps track of the group number of each.
    /// This is used to find group names
    private struct PatternGroupParser: CustomStringConvertible {
        /// Pattern of the group
        let pattern: String
        /// Name of the group
        let name: String?
        /// Index of the group
        let index: Int
        /// Any child groups
        var children: [PatternGroupParser]
        
        private init(_ pattern: String, index grpIndex: inout Int) {
             var p = pattern
            if pattern.hasPrefix("(") && pattern.hasSuffix(")")  {
                p.removeFirst() //Remove opening bracket
                p.removeLast() // Remove closing bracket
            }
           
            self.pattern = p
            self.index = grpIndex
            grpIndex += 1
            var grpName: String? = nil
            // Check if group has a name
            if p.hasPrefix("?"){
                p.removeFirst()
                if p.hasPrefix("P") || p.hasPrefix("'") { p.removeFirst() }
                if let r = p.range(of: ">"), p.hasPrefix("<") {
                    grpName = String(p[p.index(after: p.startIndex)..<r.lowerBound])
                    
                    p = String(p[r.upperBound...])
                }
            }
            self.name = grpName
            
            var currentIndex: String.Index = p.startIndex
            
            var subGroups: [PatternGroupParser] = []
            
            var inGroups: Int = 0
            var startOfGroup: String.Index? = nil
            while currentIndex < p.endIndex {
                if p[currentIndex] == "(" &&
                    (currentIndex == p.startIndex || p[p.index(before: currentIndex)] != "\\") {
                    inGroups += 1
                    if startOfGroup == nil { startOfGroup = currentIndex }
                } else if p[currentIndex] == ")" &&
                       (currentIndex > p.startIndex || p[p.index(before: currentIndex)] != "\\") {
                    inGroups -= 1
                    if let startGroup = startOfGroup, inGroups == 0 {
                        let subPattern = String(p[startGroup...currentIndex])
                        startOfGroup = nil
                        let subGroup = PatternGroupParser(subPattern, index: &grpIndex)
                        subGroups.append(subGroup)
                    }
                }
                currentIndex = p.index(after: currentIndex)
            }
            
            
            self.children = subGroups
        }
        
        init(_ pattern: String) {
            var groupCounter: Int = 0
            self.init("(\(pattern))", index: &groupCounter)
        }
        
        var description: String {
            var rtn: String = "Group(name: "
            if let n = self.name { rtn += "\"\(n)\", " }
            else { rtn += "nil, " }
            rtn += "index: \(self.index), "
            rtn += "pattern: '\(self.pattern)'"
            if self.children.count > 0 {
                rtn += ", "
                rtn += "children: \(self.children)"
            }
            rtn += ")"
            return rtn
        }
        /// Dictionary of any named groups and their corresponding group indexes
        var namedGroups: [String: [Int]] {
            var rtn: [String: [Int]] = [:]
            
            for child in self.children {
                if let n = child.name {
                    if var ary = rtn[n] {
                        if !ary.contains(child.index) {
                            ary.append(child.index)
                            ary.sort()
                            rtn[n] = ary
                        }
                    } else {
                        rtn[n] = [child.index]
                    }
                }
                for (n,v) in child.namedGroups {
                    if var ary = rtn[n] {
                        for val in v {
                            if !ary.contains(val) {
                               ary.append(child.index)
                           }
                        }
                        ary.sort()
                        rtn[n] = ary
                    } else {
                       rtn[n] = v
                    }
                    
                    if !rtn.keys.contains(n) {
                         rtn[n] = v
                    }
                }
            }
            return rtn
        }
    }
    /// An occurrence of textual content found during the analysis of a block of text, such as when matching a regular expression.
    public struct Match {
        /// Returns the range of the result that the receiver represents.
        public let range: Range<String.Index>
        /// The value matching the given pattern
        public let value: String
        private let ranges: [Range<String.Index>?]
        
        fileprivate let textResults: NSTextCheckingResult
        public let pattern: RegEx
        
        /// Returns an array of the unique capture group names
        public var captureGroupNames: [String] { return self.pattern.captureGroupNames }
        
        /// The number of groups
        public var count: Int { return ranges.count }
        
        internal init(from value: String, using pattern: RegEx, with textResults: NSTextCheckingResult) {
            let r = Range<String.Index>(textResults.range, in: value)!
            var rAry: [Range<String.Index>?] = []
            for i in 0..<textResults.numberOfRanges {
                rAry.append(Range<String.Index>(textResults.range(at: i), in: value))
            }
            //self.init(range: r, ranges: rAry)
            self.range = r
            self.value = value
            self.ranges = rAry
            self.pattern = pattern
            self.textResults = textResults
            
        }
        
        /// Get the range of the group with the given index.  If the group did not match, this will return nil
        public func range(at index: Int) -> Range<String.Index>? { return self.ranges[index] }
        
        /// Get the range of the group with the given group name.  If the group did not match, or the name does not exist, this will return nil
        public func range(withName name: String) -> Range<String.Index>? {
            guard let positions = self.pattern._capturedGroups[name],
                  let firstPosition = positions.first else { return nil }
            return self.ranges[firstPosition]
            //return Range<String.Index>(self.textResults.range(withName: name), in: self.string)
        }
        
        /// The value for the group with the corresponding index
        public func value(at index: Int) -> String? {
            guard let r = self.ranges[index] else { return  nil }
            return String(self.value[r])
        }
        /// The value for the group with the corresponding name
        public func value(withName name: String) -> String? {
            guard let r = self.range(withName: name) else { return  nil }
            return String(self.value[r])
        }
        /// Returns a new text checking result after adjusting the ranges as specified by the offset.
        public func adjustingRanges(offset: Int) -> Match {
            return Match(from: self.value, using: self.pattern, with: self.textResults.adjustingRanges(offset: offset))
        }
    }
    
    /// These constants define the regular expression options. These constants are used by the property options init(pattern:options:).
    public struct Options : OptionSet {
        
        public let rawValue: UInt
        
        public init(rawValue: UInt) { self.rawValue = rawValue }
        internal init(_ value: NSRegularExpression.Options) { rawValue =  value.rawValue}
        
        
        private static let FLAG_CONVERSION: [Character: Options] = [
            "i": .caseInsensitive,
            "s": .dotMatchesLineSeparators,
            "m": .anchorsMatchLines,
            "W": .allowCommentsAndWhitespace,
            "E": .ignoreMetacharacters,
            "L": .useUnixLineSeparators,
            "B": .useUnicodeWordBoundaries,
        ]
        
        /// String representation of flag options
        public var flagString: String {
            var rtn: String = ""
            for k in Options.FLAG_CONVERSION.keys.sorted(by: { return String($0).lowercased() < String($1).lowercased() }) {
                let v = Options.FLAG_CONVERSION[k]!
                if self.contains(v) { rtn += String(k) }
            }
            return rtn
        }
        
        /// Creation an option based on the character flag representation
        /// If an invalid character is provided nil will be returned
        /// - Parameter flag: The character flag for this option
        public init?(_ flag: Character) {
            guard let val = Options.FLAG_CONVERSION[flag] else { return nil }
            self = val
        }
        
        /// Match letters in the pattern independent of case.
        public static let caseInsensitive: Options = Options(NSRegularExpression.Options.caseInsensitive)
        
        /// Ignore whitespace and #-prefixed comments in the pattern.
        public static var allowCommentsAndWhitespace: Options = Options(NSRegularExpression.Options.allowCommentsAndWhitespace)
        
        /// Treat the entire pattern as a literal string.
        public static var ignoreMetacharacters: Options = Options(NSRegularExpression.Options.ignoreMetacharacters)
        
        /// Allow . to match any character, including line separators.
        public static var dotMatchesLineSeparators: Options = Options(NSRegularExpression.Options.dotMatchesLineSeparators)
        
        /// Allow ^ and $ to match the start and end of lines.
        public static var anchorsMatchLines: Options = Options(NSRegularExpression.Options.anchorsMatchLines)
        
        /// Treat only \n as a line separator (otherwise, all standard line separators are used).
        public static var useUnixLineSeparators: Options = Options(NSRegularExpression.Options.useUnixLineSeparators)
        
        /// Use Unicode TR#29 to specify word boundaries (otherwise, traditional regular expression word boundaries are used).
        public static var useUnicodeWordBoundaries: Options = Options(NSRegularExpression.Options.useUnicodeWordBoundaries)
        
        /// The NSRegularExpression.Options representation of this object
        public var nsValue: NSRegularExpression.Options { return NSRegularExpression.Options(rawValue: self.rawValue) }
        
        /// Option set with all conditions
        public static let all: Options = [.caseInsensitive,
                                          .allowCommentsAndWhitespace,
                                          .ignoreMetacharacters,
                                          .dotMatchesLineSeparators,
                                          .anchorsMatchLines,
                                          .useUnixLineSeparators,
                                          .useUnicodeWordBoundaries]
        
    }
    
    /// The matching options constants specify the reporting, completion and matching rules to the expression matching methods. These constants are used by all methods that search for, or replace values, using a regular expression.
    public struct MatchingOptions : OptionSet {
        
        public let rawValue: UInt
        
        public init(rawValue: UInt) { self.rawValue = rawValue }
        internal init(_ value: NSRegularExpression.MatchingOptions) { rawValue =  value.rawValue}
        
        /// Call the block periodically during long-running match operations.
        public static let reportProgress: MatchingOptions = MatchingOptions(NSRegularExpression.MatchingOptions.reportProgress)
        
        /// Call the block once after the completion of any matching.
        public static let reportCompletion: MatchingOptions = MatchingOptions(NSRegularExpression.MatchingOptions.reportCompletion)
        
        /// Limit matches to those at the start of the search range.
        public static let anchored: MatchingOptions = MatchingOptions(NSRegularExpression.MatchingOptions.anchored)
        
        /// Allow matching to look beyond the bounds of the search range.
        public static let withTransparentBounds: MatchingOptions = MatchingOptions(NSRegularExpression.MatchingOptions.withTransparentBounds)
        
        /// Prevent ^ and $ from automatically matching the beginning and end of the search range.
        public static let withoutAnchoringBounds: MatchingOptions = MatchingOptions(NSRegularExpression.MatchingOptions.withoutAnchoringBounds)
        
        /// The NSRegularExpression.MatchingOptions representation of this object
        public var nsValue: NSRegularExpression.MatchingOptions { return NSRegularExpression.MatchingOptions(rawValue: self.rawValue) }
    }
    
    /// Set by the Block as the matching progresses, completes, or fails. Used by the method enumerateMatches(in:options:range:using:).
    public struct MatchingFlags : OptionSet {
        
        public let rawValue: UInt
        
        public init(rawValue: UInt) { self.rawValue = rawValue }
        internal init(_ value: NSRegularExpression.MatchingFlags) { rawValue =  value.rawValue}
        
        /// Set when the block is called to report progress during a long-running match operation.
        public static let progress: MatchingFlags = MatchingFlags(NSRegularExpression.MatchingFlags.progress)
        
        /// Set when the block is called after completion of any matching.
        public static let completed: MatchingFlags = MatchingFlags(NSRegularExpression.MatchingFlags.completed)
        
        /// Set when the current match operation reached the end of the search range.
        public static let hitEnd: MatchingFlags = MatchingFlags(NSRegularExpression.MatchingFlags.hitEnd)
        
        /// Set when the current match depended on the location of the end of the search range.
        public static let requiredEnd: MatchingFlags = MatchingFlags(NSRegularExpression.MatchingFlags.requiredEnd)
        
        /// Set when matching failed due to an internal error.
        public static let internalError: MatchingFlags = MatchingFlags(NSRegularExpression.MatchingFlags.internalError)
        
        /// The NSRegularExpression.MatchingFlags representation of this object
        public var nsValue: NSRegularExpression.MatchingFlags { return NSRegularExpression.MatchingFlags(rawValue: self.rawValue) }
    }
    
    /// Indicator if we should not throw an error when parsing well documented regular expression flags that are unsupported in Swift like g, u and y
    /// Unsupported option flags are stored in KNOWN_UNSUPPORTED_REGEX_STR_OPTIONS
    public static var ALLOW_KNOWN_UNSUPPORTED_REGX_STR_OPTIONS: Bool = false
    /// List of known option flags that are unsupported
    public static var KNOWN_UNSUPPORTED_REGEX_STR_OPTIONS: [Character] = ["g", "u", "y"]
    
    fileprivate var nsRegex: NSRegularExpression
    private let _capturedGroups: [String: [Int]]
    
    /// Returns the regular expression pattern.
    public let pattern: String
    /// Returns the options used when the regular expression option was created.
    public let options: Options
    /// Returns the number of capture groups in the regular expression.
    public var numberOfCaptureGroups: Int { return nsRegex.numberOfCaptureGroups }
    
    /// Returns an array of the unique capture group names
    public var captureGroupNames: [String] { return Array<String>(self._capturedGroups.keys).sorted() }
    
    /// Parsed Option Flags
    private let parsedOptionFlags: String?
    
    /// String representing the regular expression including option flags if any were set
    public var string: String {
        let optionStr: String = self.parsedOptionFlags ?? self.options.flagString
        
        var string = self.pattern
        if !optionStr.isEmpty {
            string = "/" + string + "/" + optionStr
        }
        
        return string
    }
    
    private init(pattern: String, options: RegEx.Options = [], parsedOptionFlags: String?) throws {
        self.options = options
        self.pattern = pattern
        self.parsedOptionFlags = parsedOptionFlags
        
        self.nsRegex = try NSRegularExpression(pattern: pattern, options: options.nsValue)
        self._capturedGroups = PatternGroupParser(pattern).namedGroups
        super.init()
    }
    /// Returns an initialized RegEx instance with the specified regular expression pattern and options.
    ///
    /// - Parameter pattern The regular expression pattern to compile.
    /// - Parameter options The regular expression options that are applied to the expression during matching. See RegEx.Options for possible values.
    ///
    /// - Returns: An instance of RegEx for the specified regular expression and options.
    public convenience init(pattern: String, options: RegEx.Options = []) throws {
        try self.init(pattern:  pattern, options: options, parsedOptionFlags: nil)
    }
    
    /// Create a new regular expression object from its string representation
    /// - Parameter string: The string representing the regular expression object
    /// - Throws: Throws error on invalid string
    public convenience init(_ string: String) throws {
        var pattern = string
        var options = RegEx.Options()
        var parsedOptionFlags: String? = nil
        if pattern.hasPrefix("/"),
           let r = pattern.range(of: "/", options: [.backwards, .literal]),
           r.lowerBound != pattern.startIndex {
            
            let indexOfLastSlash = r.lowerBound
            //let indexAfterLastSlash = r.upperBound
        
            //let indexOfLastSlash = indexOfLastSlash
            let indexAfterLastSlash = pattern.index(after: indexOfLastSlash)

           
            // Grab pattern options
            let optionStr = String(pattern.suffix(from: indexAfterLastSlash))
           
            // Remove options from pattern
            pattern = String(pattern.prefix(upTo: indexOfLastSlash))
            
            // Remove beginning slash
            pattern.removeFirst()
           
           var invalidOptions: String = ""
           for option in optionStr {
                if let opt = Options(option) {
                    options.insert(opt)
                    if parsedOptionFlags == nil { parsedOptionFlags = "" }
                    parsedOptionFlags! += String(option)
                } else if RegEx.ALLOW_KNOWN_UNSUPPORTED_REGX_STR_OPTIONS && RegEx.KNOWN_UNSUPPORTED_REGEX_STR_OPTIONS.contains(option) {
                     if parsedOptionFlags == nil { parsedOptionFlags = "" }
                    parsedOptionFlags! += String(option)
                } else {
                    invalidOptions += String(option)
                }
           }
           if !invalidOptions.isEmpty {
               throw Errors.parsedInvalidOptionFlags(invalidOptions)
           }
        }
       
        try self.init(pattern: pattern, options: options, parsedOptionFlags: parsedOptionFlags)
    }
    
    /// This constructor allows for converting from string literal.  Will cause a fatal error if the string is not a valid regular expression string
    public required convenience init(stringLiteral value: String) {
        do { try self.init(value) }
        catch { fatalError("\(error)") }
    }

    public convenience init(from decoder: Decoder) throws {
        let pattern = try decoder.singleValueContainer().decode(String.self)
        
        try self.init(pattern)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.string)
        
    }
    
    private func nsRange(_ string: String, from range: @autoclosure () -> Range<String.Index>?) -> NSRange {
        return NSRange(range() ?? string._regExFullRange, in: string)
    }
    
    
    /// Returns the number of matches of the regular expression within the specified range of the string.
    ///
    /// - Parameter string: The string to search.
    /// - Parameter options: The matching options to use. See RegEx.MatchingOptions for possible values.
    /// - Parameter range: The range of the string to search.
    ///
    /// Returns: The number of matches of the regular expression.
    public func numberOfMatches(in string: String,
                                options: RegEx.MatchingOptions = [],
                                range: Range<String.Index>? = nil) -> Int {
        return nsRegex.numberOfMatches(in: string,
                                       options: options.nsValue,
                                       range: self.nsRange(string, from: range))
    }
    
    /// Enumerates the string allowing the Block to handle each regular expression match.
    ///
    /// - Parameter string: The string.
    /// - Parameter options: The matching options to report. See RegEx.MatchingOptions for the supported values.
    /// - Parameter range: The range of the string to test.
    /// - Parameter block: The Block enumerates the matches of the regular expression in the string.
    ///The block takes three arguments:
    ///
    /// - Parameter result: An RegEx.Match specifying the match. This result gives the overall matched range via its range property, and the range of each individual capture group via its range(at:) method. The range nil is returned if one of the capture groups did not participate in this particular match.
    /// - Parameter flags: The current state of the matching progress. See RegEx.MatchingFlags for the possible values.
    /// - Parameter stop: A reference to a Boolean value. The Block can set the value to true to stop further processing of the array. The stop argument is an out-only argument. You should only ever set this Boolean to true within the Block.
    ///
    /// - Returns: The Block returns void.
    public func enumerateMatches(in string: String,
                                 options: RegEx.MatchingOptions = [],
                                 range: Range<String.Index>? = nil,
                                 using block: @escaping (_ result: RegEx.Match?, _ flags: RegEx.MatchingFlags, _ stop: inout Bool) -> Void) {
        
        //nsRegex.enumerateMatches(in: string, options: options.nsValue, range: self.toNSRange(with: string, range)) {
        nsRegex.enumerateMatches(in: string,
                                 options: options.nsValue,
                                 range: self.nsRange(string, from: range)) { tcr, f, ump in
            
            var txtCheckignResults: Match? = nil
            if let t = tcr {
                txtCheckignResults = Match(from: string, using: self, with: t)
            }
            let flags: MatchingFlags = MatchingFlags(f)
            
            var stop: Bool = false
            block(txtCheckignResults, flags, &stop)
            
            ump.pointee = ObjCBool(stop)
            
        }
        
    }
    
    /// Returns an array containing all the matches of the regular expression in the string.
    ///
    /// - Parameter string: The string to search.
    /// - Parameter options: The matching options to use. See NSRegularExpression.MatchingOptions for possible values.
    /// - Parameter range: The range of the string to search.
    ///
    /// - Returns: An array of RegEx.Match objects. Each result gives the overall matched range via its range property, and the range of each individual capture group via its range(at:) method. The nil is returned if one of the capture groups did not participate in this particular match.
    public func matches(in string: String,
                        options: RegEx.MatchingOptions = [],
                        range: Range<String.Index>? = nil) -> [Match] {
        let vals: [NSTextCheckingResult] = self.nsRegex.matches(in: string,
                                                                options: options.nsValue,
                                                                range: self.nsRange(string, from: range))
        return vals.map({Match(from: string, using: self, with: $0)})
    }
    
    /// Returns the first match of the regular expression within the specified range of the string.
    ///
    /// - Parameter string: The string to search.
    /// - Parameter options: The matching options to use. See RegEx.MatchingOptions for possible values.
    /// - Parameter range: The range of the string to search.
    ///
    /// - Returns: An RegEx.Match object. This result gives the overall matched range via its range property, and the range of each individual capture group via its range(at:) method. The nil is returned if one of the capture groups did not participate in this particular match.
    public func firstMatch(in string: String,
                           options: RegEx.MatchingOptions = [],
                           range: Range<String.Index>? = nil) -> Match? {
        
        guard let tcr = self.nsRegex.firstMatch(in: string,
                                                options: options.nsValue,
                                                range: self.nsRange(string, from: range)) else { return nil }
        return Match(from: string, using: self, with: tcr)
       
        
    }
    
    /// Returns the range of the first match of the regular expression within the specified range of the string.
    ///
    /// - Parameter string: The string to search.
    /// - Parameter options: The matching options to use. See RegEx.MatchingOptions for possible values.
    /// - Parameter range: The range of the string to search.
    /// - Returns: The range of the first match. Returns nil if no match is found.
    public func rangeOfFirstMatch(in string: String,
                                  options: RegEx.MatchingOptions = [],
                                  range: Range<String.Index>? = nil) -> Range<String.Index>? {
        let nsRange = self.nsRegex.rangeOfFirstMatch(in: string,
                                                     options: options.nsValue,
                                                     range: self.nsRange(string, from: range))
        
        return Range<String.Index>(nsRange, in: string)
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? RegEx else { return false }
        return (self.pattern == rhs.pattern &&
                self.options == rhs.options &&
                self.parsedOptionFlags == rhs.parsedOptionFlags )
    }
    
}

public extension RegEx {
    /// Returns a new string containing matching regular expressions replaced with the template string.
    ///
    /// See Flag Options for the format of template.
    ///
    /// - Parameter string: The string to search for values within.
    /// - Parameter options: The matching options to use. See RegEx.MatchingOptions for possible values.
    /// - Parameter range: The range of the string to search.
    /// - Parameter templ: The substitution template used when replacing matching instances.
    ///
    /// - Returns: A string with matching regular expressions replaced by the template string.
    func stringByReplacingMatches(in string: String,
                                  options: RegEx.MatchingOptions = [],
                                  range: Range<String.Index>? = nil,
                                  withTemplate templ: String) -> String {
        
        return self.nsRegex.stringByReplacingMatches(in: string,
                                                     options: options.nsValue,
                                                     range: self.nsRange(string, from: range),
                                                     withTemplate: templ)
        
    }
    
    /// Replaces regular expression matches within the mutable string using the template string.
    ///
    /// See Flag Options for the format of template.
    ///
    /// - Parameter string: The mutable string to search and replace values within.
    /// - Parameter options: The matching options to use. See RegEx.MatchingOptions for possible values.
    /// - Parameter range: The range of the string to search.
    /// - Parameter templ: The substitution template used when replacing matching instances.
    ///
    /// - Returns: The number of matches.
    func replaceMatches(in string: inout String,
                        options: RegEx.MatchingOptions = [],
                        range: Range<String.Index>? = nil,
                        withTemplate templ: String) -> Int {
        
        let s = NSMutableString(string: string)
        let nRange = self.nsRange(string, from: range)
        let rtn = self.nsRegex.replaceMatches(in: s,
                                              options: options.nsValue,
                                              range: nRange,
                                              withTemplate: templ)
        
        //string = s as String
        string = String(describing: s)
        return rtn
    }
    
    
    /// Used to perform template substitution for a single result for clients implementing their own replace functionality.
    ///
    /// For clients implementing their own replace functionality, this is a method to perform the template substitution for a single result, given the string from which the result was matched, an offset to be added to the location of the result in the string (for example, in cases that modifications to the string moved the result since it was matched), and a replacement template.
    ///
    /// This is an advanced method that is used only if you wanted to iterate through a list of matches yourself and do the template replacement for each one, plus maybe some other calculation that you want to do in code, then you would use this at each step.
    ///
    /// - Parameter result: The result of the single match.
    /// - Parameter string: The string from which the result was matched.
    /// - Parameter offset: The offset to be added to the location of the result in the string.
    /// - Parameter templ: See Flag Options for the format of template.
    ///
    /// - Returns: A replacement string.
    func replacementString(for result: Match,
                           in string: String,
                           offset: String.Index,
                           template templ: String) -> String {
        let strOffset = string.distance(from: string.startIndex, to: offset)
        return self.nsRegex.replacementString(for: result.textResults, in: string, offset: strOffset, template: templ)
        
    }
    
    
    /// Returns a string by adding backslash escapes as necessary to protect any characters that would match as pattern metacharacters.
    ///
    /// Returns a string by adding backslash escapes as necessary to the given string, to escape any characters that would otherwise be treated as pattern metacharacters. You typically use this method to match on a particular string within a larger pattern.
    ///
    /// For example, the string "(N/A)" contains the pattern metacharacters (, /, and ). The result of adding backslash escapes to this string is "\\(N\\/A\\)".
    /// - Parameter string: The string.
    /// - Returns: The escaped string.
    class func escapedPattern(for string: String) -> String {
       return NSRegularExpression.escapedPattern(for: string)
    }
    
    /// Returns a template string by adding backslash escapes as necessary to protect any characters that would match as pattern metacharacters
    ///
    /// Returns a string by adding backslash escapes as necessary to the given string, to escape any characters that would otherwise be treated as pattern metacharacters. You typically use this method to match on a particular string within a larger pattern.
    ///
    /// For example, the string "(N/A)" contains the pattern metacharacters (, /, and ). The result of adding backslash escapes to this string is "\\(N\\/A\\)".
    ///
    /// See Flag Options for the format of the resulting template string.
    /// - Parameter string: The template string
    /// - Returns: The escaped template string.
    class func escapedTemplate(for string: String) -> String {
        return NSRegularExpression.escapedTemplate(for: string)
    }
}
