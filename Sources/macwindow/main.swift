import Foundation
import MacWindowCore

do {
    let command = try Command.parse(Array(CommandLine.arguments.dropFirst()))
    let macwindow = MacWindow(executablePath: Bundle.main.executablePath ?? CommandLine.arguments[0])
    try macwindow.run(command)
} catch {
    FileHandle.standardError.write(Data("macwindow: \(error)\n".utf8))
    exit(1)
}
