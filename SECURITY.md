# Security Policy

## Supported versions

Security fixes land on the latest minor release. Users are expected to stay on the most recent tagged version.

| Version | Supported |
|---|---|
| 1.x     | ✅ |
| < 1.0   | ❌ |

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security problems.

Instead, report privately via one of:

- GitHub's private vulnerability reporting: <https://github.com/juxstin1/archmap-plugin/security/advisories/new>
- Email the maintainer with `[archmap security]` in the subject line (contact via the GitHub profile at <https://github.com/juxstin1>)

Please include:

- A description of the issue and the component affected (command, agent, hook, template)
- Steps to reproduce (ideally a minimal repo or payload)
- The impact you believe it has (data exposure, code execution, denial of service, etc.)
- Your preferred credit name, or a note if you'd rather stay anonymous

You should receive an acknowledgement within a few days. We aim to ship a fix or a mitigation plan within two weeks for high-severity issues.

## Scope

In-scope for this policy:

- The HTML template (`templates/archmap-template.html`) — XSS, injection via project data, self-contained-guarantee leaks
- Hook scripts (`hooks/scripts/*.sh`) — command injection, path traversal, unsafe stdin handling
- Command and agent prompts — prompt-injection paths that could cause a malicious repository to extract data or execute unintended actions
- `.archmap.json` parsing — anything that could turn a hostile config into code execution

Out of scope:

- Issues in Claude Code itself — report those to Anthropic
- Issues in the projects being mapped — Archmap reads but does not modify user code
