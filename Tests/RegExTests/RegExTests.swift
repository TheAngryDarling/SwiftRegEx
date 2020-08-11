import XCTest
@testable import RegEx

public func XCTNotThrown(_ block: @autoclosure () throws -> Void,
                         _ message: @autoclosure () -> String = "",
                         file: StaticString = #file,
                         line: UInt = #line) {
    do {
        try block()
    } catch {
        var msg: String = message()
        if !msg.isEmpty { msg += "\n" }
        msg += "\(error)"
        XCTFail(msg, file: file, line: line)
    }
}

public func XCTNotThrown<R>(_ block: @autoclosure () throws -> R,
                            _ message: @autoclosure () -> String = "",
                            file: StaticString = #file,
                            line: UInt = #line) -> R? {
    do {
        return try block()
    } catch {
        var msg: String = message()
        if !msg.isEmpty { msg += "\n" }
        msg += "\(error)"
        XCTFail(msg, file: file, line: line)
        return nil
    }
}

public func XCTNotThrown<R>(_ block: @autoclosure () throws -> R?,
                            _ message: @autoclosure () -> String = "",
                            file: StaticString = #file,
                            line: UInt = #line) -> R? {
    do {
        return try block()
    } catch {
        var msg: String = message()
        if !msg.isEmpty { msg += "\n" }
        msg += "\(error)"
        XCTFail(msg, file: file, line: line)
        return nil
    }
}

class RegExTests: XCTestCase {
    
    let showName = "TV Show"
    let showSeason = "11"
    let showEpisode = "02"
    let showTitle = "Title"
    let seperator = " "
    lazy var string = "\(showName)\(seperator)S\(showSeason)E\(showEpisode)\(seperator)\(showTitle)"
    let pattern = "(?<show>.+)(?<seperator>\\.|\\-| )[sS](?<season>(?<seasonFirstDigit>\\d)\\d+)[eE](?<episode>\\d+)(\\k<seperator>)(?<title>.+)"
    
    let unsupportedFlags = String(RegEx.KNOWN_UNSUPPORTED_REGEX_STR_OPTIONS)
    let supportedFlags = RegEx.Options.all.flagString
    lazy var patternFlags = unsupportedFlags + supportedFlags
    
    func testPattern() {
    
        if let p = XCTNotThrown(try string.firstMatch(pattern: pattern)) {
            let groupNames = p.captureGroupNames
             XCTAssertTrue(groupNames.contains("episode"))
             XCTAssertTrue(groupNames.contains("season"))
             XCTAssertTrue(groupNames.contains("seasonFirstDigit"))
             XCTAssertTrue(groupNames.contains("seperator"))
             XCTAssertTrue(groupNames.contains("show"))
             XCTAssertTrue(groupNames.contains("title"))
             
             XCTAssertEqual(showName, p.value(withName: "show"))
             XCTAssertEqual(showSeason, p.value(withName: "season"))
             XCTAssertEqual(String(showSeason.first!), p.value(withName: "seasonFirstDigit"))
             XCTAssertEqual(showEpisode, p.value(withName: "episode"))
             XCTAssertEqual(showTitle, p.value(withName: "title"))
             XCTAssertEqual(seperator, p.value(withName: "seperator"))
        }
    }
    
    
    func testParsePatternString() {
        RegEx.ALLOW_KNOWN_UNSUPPORTED_REGX_STR_OPTIONS = true
        
        // Test parsing all known flags
        if let r = XCTNotThrown(try RegEx("/" + pattern + "/" + patternFlags)) {
            for flag in patternFlags {
                if let option = RegEx.Options(flag) {
                     XCTAssertTrue(r.options.contains(option), "Missing Option \(option)")
                }
            }
            XCTAssertEqual("/" + pattern + "/" + patternFlags, r.string)
        }
        
        // Test parsing all known flags
        let modPatternFlags = String(patternFlags.dropLast())
        let removedPatternFlags = patternFlags.replacingOccurrences(of: modPatternFlags, with: "")
        
        if let r = XCTNotThrown(try RegEx("/" + pattern + "/" + modPatternFlags)) {
            for flag in modPatternFlags {
                if let option = RegEx.Options(flag) {
                     XCTAssertTrue(r.options.contains(option), "Missing Option \(option)")
                }
            }
            for flag in removedPatternFlags {
                if let option = RegEx.Options(flag) {
                     XCTAssertFalse(r.options.contains(option), "Had Option \(option)")
                }
            }
            XCTAssertEqual("/" + pattern + "/" + modPatternFlags, r.string)
        }
    }
    func testParsePatternStringErrors() {
        RegEx.ALLOW_KNOWN_UNSUPPORTED_REGX_STR_OPTIONS = false
        XCTAssertThrowsError(try RegEx("/" + pattern + "/" + patternFlags),
                             "Invalid flags should have thrown error") { err in
            guard case RegEx.Errors.parsedInvalidOptionFlags(let flags) = err else {
                fatalError("Unexpected error: \(err)")
            }
           XCTAssertEqual(unsupportedFlags, flags)
        }
        RegEx.ALLOW_KNOWN_UNSUPPORTED_REGX_STR_OPTIONS = true
        let badFlags = "Z23"
        XCTAssertThrowsError(try RegEx("/" + pattern + "/\(patternFlags)\(badFlags)"),
                             "Invalid flags should have thrown error") { err in
            guard case RegEx.Errors.parsedInvalidOptionFlags(let flags) = err else {
                fatalError("Unexpected error: \(err)")
            }
           XCTAssertEqual(badFlags, flags)
        }
    }
    
    func testStringLiteral() {
        // Basic Pattern
        let _: RegEx = "(.+)"
        // Pattern with Flag caseInsensitive
        let _: RegEx = "/(.+)/i"
    }
    
    func testCoding() {
        
        struct Container: Codable {
            let regex: RegEx
        }
        
        if true {
            RegEx.ALLOW_KNOWN_UNSUPPORTED_REGX_STR_OPTIONS = true
            
            let fullPattern = "/" + pattern + "/" + patternFlags
            
            if let r = XCTNotThrown(try RegEx(fullPattern)) {
                let container = Container(regex: r)
                if let encodedData = XCTNotThrown(try JSONEncoder().encode(container)) {
                    if let decodedContainer = XCTNotThrown(try JSONDecoder().decode(Container.self, from: encodedData)) {
                        XCTAssertEqual(decodedContainer.regex, r)
                        XCTAssertEqual(decodedContainer.regex.string, fullPattern)
                    }
                }
            }
        }
        
        if true {
            RegEx.ALLOW_KNOWN_UNSUPPORTED_REGX_STR_OPTIONS = true
            
            let fullPattern = pattern
            
            if let r = XCTNotThrown(try RegEx(fullPattern)) {
                let container = Container(regex: r)
                if let encodedData = XCTNotThrown(try JSONEncoder().encode(container)) {
                    if let decodedContainer = XCTNotThrown(try JSONDecoder().decode(Container.self, from: encodedData)) {
                         XCTAssertEqual(decodedContainer.regex, r)
                         XCTAssertEqual(decodedContainer.regex.string, fullPattern)
                    }
                }
            }
        }
        
        
    }
    
    


    static var allTests = [
        ("testPattern", testPattern),
        ("testParsePatternString", testParsePatternString),
        ("testParsePatternStringErrors", testParsePatternStringErrors),
        ("testStringLiteral", testStringLiteral),
        ("testCoding", testCoding)
    ]
}
