---
name: code-review
description: Review code for security vulnerabilities, business logic correctness, performance issues, and over-engineering. Use this skill before opening a PR, after AI generates code, when reviewing diffs, or whenever code quality or OWASP compliance needs checking. Trigger on "review code", "check for vulnerabilities", "OWASP", "PR review", "code quality", "security audit".
---

# Skill: Code Review

## Steps

1. **Security (OWASP Top 10)**
   - Check for injection vulnerabilities (SQL, command, XSS)
   - Verify authentication and authorization on all endpoints
   - Look for sensitive data exposure (secrets in code, verbose errors)
   - Check for insecure deserialization and CSRF
2. **Business Logic Correctness**
   - Verify the code does what the requirements specify
   - Check edge cases: nulls, empty collections, boundary values
   - Confirm error states are handled and communicated correctly
3. **Error Handling**
   - Ensure exceptions are caught at appropriate levels
   - Verify logging includes context (correlation ID, user, action)
   - Confirm no silent swallowing of errors
4. **Performance**
   - Check for N+1 query patterns (especially in loops hitting DB/API)
   - Look for unbounded collections or missing pagination
   - Verify proper use of async/await where applicable
   - Check for unnecessary allocations or repeated computation
5. **Over-Engineering**
   - Flag unnecessary abstractions (interfaces with single implementations)
   - Identify premature generalization
   - Check for dead code or unused parameters

## Output Format

| # | File             | Line | Type        | Severity | Finding                      | Suggested Fix              |
|---|------------------|------|-------------|----------|------------------------------|----------------------------|
| 1 | src/foo/bar.cs   | 42   | Security    | High     | SQL concatenation            | Use parameterized query    |
| 2 | src/baz/qux.py   | 15   | Performance | Medium   | N+1 in loop                  | Batch fetch before loop    |
| 3 | src/web/page.tsx | 88   | Logic       | Low      | Missing null check           | Add guard clause           |

## Rules

- Always review the full diff, not just the files you are familiar with
- Severity levels: Critical, High, Medium, Low, Info
- Every finding must include a concrete suggested fix
- Do not nitpick formatting if a linter/formatter is configured
- If no issues are found, explicitly state "No findings" (do not fabricate issues)
