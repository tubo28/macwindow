import Foundation
import Testing

@testable import MacWindowCore

@Suite("The launch agent")
struct LaunchAgentTests {
    @Test("Describes an agent that listens for the shortcuts from login onwards")
    func plistContents() throws {
        let data = Data(LaunchAgent.plist(executablePath: "/usr/local/bin/macwindow").utf8)

        let plist =
            try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]

        #expect(plist?["Label"] as? String == "com.github.tubo28.macwindow")
        #expect(plist?["ProgramArguments"] as? [String] == ["/usr/local/bin/macwindow", "watch"])
        #expect(plist?["RunAtLoad"] as? Bool == true)
        #expect(plist?["KeepAlive"] as? Bool == true)
    }

    @Test("Lives in the user's LaunchAgents directory under its label")
    func location() {
        #expect(LaunchAgent.plistURL.lastPathComponent == "com.github.tubo28.macwindow.plist")
        #expect(LaunchAgent.plistURL.deletingLastPathComponent().lastPathComponent == "LaunchAgents")
    }
}
