# Project outline

This library can be divided into three components:

- **The "joinable" framework:** provides [a general abstraction](state-management-theory.pdf) for [CRDT](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type) and [OT](https://en.wikipedia.org/wiki/Operational_transformation)-based synchronisation strategies.
- **The "reactive" framework:** provides basic abstractions for the [observer pattern](https://en.wikipedia.org/wiki/Observer_pattern).
- **The object graph:** a "joinable" and "reactive" graph for storing `struct`s, and macros for linking `struct` definitions to the graph.
