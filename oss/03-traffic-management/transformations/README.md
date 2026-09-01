# Transformations

Rewrite request/response headers and bodies from a template.

The engine is **rustformation** — a Rust Envoy dynamic module using
[MiniJinja](https://github.com/mitsuhiko/minijinja) templates. The older C++
Inja filter was the default in 2.1.x, the fallback in 2.2.x, and is removed in
2.3.x and later, so `USE_RUST_FORMATIONS` / `useRustFormations` no longer do
anything. The syntax is close to the old one, but there are real differences —
notably `body.parseAs` now defaults to `AsString` (the body is no longer parsed
as JSON just because a transformation exists), and JSON keys with non-identifier
characters need bracket notation.

Docs: <https://kgateway.dev/docs/envoy/latest/traffic-management/transformations/engines/>
