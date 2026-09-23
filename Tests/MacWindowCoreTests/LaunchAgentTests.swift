import Foundation
import Testing

@testable import MacWindowCore

@Suite("The launch agent")
struct LaunchAgentTests {
    @Test("Describes an agent that listens for the shortcuts from login onwards")
    func plistContents() throws {
        let data = Data(
            LaunchAgent.plist(
                executablePath: "/usr/local/bin/macwindow", logPath: "/tmp/macwindow.log"
            ).utf8)

        let plist =
            try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]

        #expect(plist?["Label"] as? String == "com.github.tubo28.macwindow")
        #expect(plist?["ProgramArguments"] as? [String] == ["/usr/local/bin/macwindow", "watch"])
        #expect(plist?["RunAtLoad"] as? Bool == true)
        #expect(plist?["KeepAlive"] as? Bool == true)
    }

    @Test("Keeps the agent's complaints in a log file, having no terminal to print them to")
    func plistLogsSomewhere() throws {
        let data = Data(
            LaunchAgent.plist(
                executablePath: "/usr/local/bin/macwindow", logPath: "/tmp/macwindow.log"
            ).utf8)

        let plist =
            try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]

        #expect(plist?["StandardOutPath"] as? String == "/tmp/macwindow.log")
        #expect(plist?["StandardErrorPath"] as? String == "/tmp/macwindow.log")
    }

    @Test("Lives in the user's LaunchAgents directory under its label")
    func location() {
        #expect(LaunchAgent.plistURL.lastPathComponent == "com.github.tubo28.macwindow.plist")
        #expect(LaunchAgent.plistURL.deletingLastPathComponent().lastPathComponent == "LaunchAgents")
    }
}
