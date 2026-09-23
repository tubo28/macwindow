/// What `macwindow status` prints.
public enum Status {
    public static func lines(trusted: Bool, installed: Bool, agent: AgentRecord?) -> [String] {
        let here = ["accessibility (this process): " + grant(trusted)]

        guard installed else { return here + ["login agent: not installed"] }
        guard let agent else { return here + ["login agent: installed, not running"] }

        let agentLines = [
            "login agent: running (pid \(agent.pid))",
            "accessibility (login agent): " + grant(agent.trusted),
        ]
        guard !agent.trusted else { return here + agentLines }

        return here + agentLines + [
            "  add \(agent.executablePath) under "
                + "System Settings → Privacy & Security → Accessibility,",
            "  then run: launchctl kickstart -k gui/$(id -u)/\(LaunchAgent.label)",
        ]
    }

    private static func grant(_ trusted: Bool) -> String { trusted ? "granted" : "not granted" }
}
