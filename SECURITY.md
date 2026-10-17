# Security and scope

This is a research prototype, not a hardened service for untrusted input.
Do not expose its command-line parser or generated runtime as a network
service without additional resource limits and security review.

- The proof boundary is Expr → abstract stack VM.
- Native Nat is bounded by 2^48−1.
- Parser and benchmark inputs may consume substantial memory or CPU.
- Source proofs do not verify the native C backend, Clang, FFI, or OS.

Report a security issue through the repository's private vulnerability
reporting feature if enabled, or privately contact its maintainer through
GitHub. Do not post sensitive details or secrets in a public issue.
