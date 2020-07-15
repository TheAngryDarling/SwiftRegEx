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
    
    func testPattern() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let showName = "TV Show"
        let showSeason = "11"
        let showEpisode = "02"
        let showTitle = "Title"
        let seperator = " "
        let string = "\(showName)\(seperator)S\(showSeason)E\(showEpisode)\(seperator)\(showTitle)"
        let pattern = "(?<show>.+)(?<seperator>\\.|\\-| )[sS](?<season>(?<seasonFirstDigit>\\d)\\d+)[eE](?<episode>\\d+)(\\k<seperator>)(?<title>.+)"
        
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
            
           
        } else {
            XCTFail("Pattern did not match")
        }
        
       
    }


    static var allTests = [
        ("testPattern", testPattern),
    ]
}
