import Testing

@testable import MacWindowCore

@Suite("Reading the command line")
struct CommandTests {
    @Test("Each subcommand is recognised by name")
    func subcommands() throws {
        #expect(try Command.parse(["left"]) == .move(.left))
        #expect(try Command.parse(["right"]) == .move(.right))
        #expect(try Command.parse(["maximize"]) == .move(.maximize))
        #expect(try Command.parse(["status"]) == .status)
        #expect(try Command.parse(["watch"]) == .watch)
        #expect(try Command.parse(["install"]) == .install)
        #expect(try Command.parse(["uninstall"]) == .uninstall)
    }

    @Test("No arguments, or asking for help, shows the usage")
    func help() throws {
        #expect(try Command.parse([]) == .help)
        #expect(try Command.parse(["--help"]) == .help)
        #expect(try Command.parse(["-h"]) == .help)
    }

    @Test("Anything else is refused rather than guessed at")
    func rejectsUnknownArguments() {
        #expect(throws: CommandError.self) { try Command.parse(["lft"]) }
        #expect(throws: CommandError.self) { try Command.parse(["left", "--force"]) }
        #expect(throws: CommandError.self) { try Command.parse(["status", "left"]) }
    }
}
