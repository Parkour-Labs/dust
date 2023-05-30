# Project outline

This library can be divided into four components:

- **The "joinable" framework:** provides [general abstractions](state-management-theory.pdf) for [CRDT](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type) and [OT](https://en.wikipedia.org/wiki/Operational_transformation)-based synchronisation strategies.
- **The "persistent" framework:** provides [common abstractions](../src/persistent.rs) for storing joinable structures into local databases, and controls their synchronisation with remote sources.
- **The "reactive" framework:** provides primitives for using the [observer pattern](https://en.wikipedia.org/wiki/Observer_pattern).
- **The object graph:** a "joinable", "persistent" and "reactive" graph for storing `struct`s, and macros for transforming `struct` definitions to objects linked to the graph (c.f. the [active record pattern](https://en.wikipedia.org/wiki/Active_record_pattern)).
