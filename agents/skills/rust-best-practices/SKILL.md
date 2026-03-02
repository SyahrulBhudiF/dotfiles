---
name: rust-best-practices
description: Rust LLM Coding Standard. Use when writing, refactoring, or reviewing Rust code to ensure idiomatic, safe, and maintainable outputs aligned with Rust community standards.
---
# Rust LLM Coding Standard


Purpose:
This document defines behavioral rules for Large Language Models
that generate Rust code. The goal is to ensure outputs are:

- Idiomatic
- Safe
- Maintainable
- Production-ready
- Aligned with Rust community standards

---

# 1. Authority Hierarchy

The LLM MUST follow sources in this order:

1. Rust API Guidelines  
   https://github.com/rust-lang/api-guidelines

2. Rust Style Guide  
   https://github.com/rust-lang/rust/tree/master/src/doc/style-guide

3. Rust Clippy Lints  
   https://github.com/rust-lang/rust-clippy

4. The Rust Programming Language Book  
   https://github.com/rust-lang/book

5. Rust Unofficial Patterns  
   https://github.com/rust-unofficial/patterns

If conflicts occur:
Official sources override community sources.

---

# 2. Core Generation Principles

The LLM MUST:

- Prefer compile-time guarantees over runtime checks
- Use the type system aggressively
- Prefer ownership clarity over convenience
- Avoid unnecessary allocations
- Minimize mutable state
- Produce zero-cost abstractions

---

# 3. Naming & Style Rules

Follow Rust Style Guide strictly:

- snake_case → functions, variables
- PascalCase → structs, enums, traits
- SCREAMING_SNAKE_CASE → constants

Rules:

- Small cohesive modules
- Prefer composition over inheritance
- Keep functions focused and short
- Apply `rustfmt` defaults

Reference:
https://github.com/rust-lang/rust/tree/master/src/doc/style-guide

---

# 4. Error Handling Rules

DO:

- Return `Result<T, E>`
- Use `?` operator
- Use `thiserror` for libraries
- Use `anyhow` for applications

DO NOT:

- use unwrap()
- use expect()
- panic! for normal control flow

Reference:
https://github.com/rust-lang/api-guidelines

---

# 5. Ownership & Borrowing Policy

Preference order:

borrow > reference > move > clone > Arc<Mutex>

Avoid:

- unnecessary cloning
- Rc<RefCell> as default workaround
- hidden ownership transfer

---

# 6. Async & Concurrency Rules

- Prefer Tokio ecosystem
  https://github.com/tokio-rs/tokio

- async only for IO-bound operations
- Never block inside async context
- Prefer message passing over shared mutable state

---

# 7. Idiomatic Pattern Requirements

Allowed patterns:

- Builder Pattern
- Newtype Pattern
- RAII
- Iterator Pattern
- Typestate Pattern

Reference:
https://github.com/rust-unofficial/patterns

---

# 8. Anti-Patterns (STRICTLY FORBIDDEN)

The LLM MUST NOT generate:

- Global mutable state
- Excessive cloning
- God structs
- Deep nested match chains
- Panic-driven logic
- Hidden allocations

Reference:
https://github.com/rust-unofficial/patterns/tree/main/src/anti_patterns

---

# 9. Dependency Policy

Prefer ecosystem standards:

- serde → https://github.com/serde-rs/serde
- tokio → https://github.com/tokio-rs/tokio
- axum → https://github.com/tokio-rs/axum
- tracing → https://github.com/tokio-rs/tracing
- thiserror → https://github.com/dtolnay/thiserror

Dependencies must be justified.

---

# 10. Documentation Requirements

Public APIs MUST include:

- `///` doc comments
- Usage example
- Error behavior explanation

Reference:
https://github.com/rust-lang/api-guidelines

---

# 11. Testing Requirements

Generated code SHOULD include:

- Unit tests
- Error case tests
- Edge case validation

---

# 12. Output Contract (MANDATORY)

LLM-generated code MUST:

- Compile successfully
- Pass `cargo fmt`
- Pass `cargo clippy -D warnings`
- Contain no unwrap()
- Contain no unused warnings
