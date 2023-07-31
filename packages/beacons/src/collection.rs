use rusqlite::{Connection, DropBehavior, Transaction};

use crate::{
  joinable::Clock,
  observable::{
    crdt::{ObjectGraph, ObjectGraphAggregator, ObjectSet},
    Aggregator, ObservablePersistentState, SetEvent,
  },
  persistent::vector_history::VectorHistory,
};

pub struct Collection {
  connection: Connection,
  name: &'static str,
  vector_history: VectorHistory,

  atoms: ObjectSet,
  graph: ObjectGraph,

  atom_aggregator: Aggregator<Option<Vec<u8>>>,
  node_aggregator: Aggregator<Option<u64>>,
  edge_aggregator: Aggregator<Option<(u128, u64, u128)>>,
  backedge_aggregator: Aggregator<SetEvent<u128>>,
}

fn auto_commit(connection: &mut Connection) -> Transaction<'_> {
  let mut res = connection.transaction().unwrap();
  res.set_drop_behavior(DropBehavior::Commit);
  res
}

impl Collection {
  pub fn new(mut connection: Connection, name: &'static str) -> Self {
    let mut txn = auto_commit(&mut connection);
    let vector_history = VectorHistory::new(&mut txn, name);
    let atoms = ObjectSet::new(&mut txn, name, "atoms");
    let graph = ObjectGraph::new(&mut txn, name, "graph");
    std::mem::drop(txn);
    Self {
      connection,
      name,
      vector_history,
      atoms,
      graph,
      atom_aggregator: Aggregator::new(),
      node_aggregator: Aggregator::new(),
      edge_aggregator: Aggregator::new(),
      backedge_aggregator: Aggregator::new(),
    }
  }

  pub fn get_node(&mut self, id: u128) -> Option<u64> {
    self.graph.node(&mut auto_commit(&mut self.connection), id)
  }

  pub fn set_node(&mut self, id: u128, value: Option<u64>) {
    let mut txn = auto_commit(&mut self.connection);
    let replica = self.vector_history.this();
    let clock = Clock::new(self.vector_history.latest());
    let action = ObjectGraph::action_node(clock, id, value);
    if self
      .vector_history
      .push(&mut txn, (replica, clock, String::from("graph"), postcard::to_allocvec(&action).unwrap()))
      .is_some()
    {
      self.graph.apply(
        &mut txn,
        &mut ObjectGraphAggregator {
          node_aggregator: &mut self.node_aggregator,
          edge_aggregator: &mut self.edge_aggregator,
          backedge_aggregator: &mut self.backedge_aggregator,
        },
        action,
      );
    }
  }

  pub fn subscribe_node(&mut self, id: u128, port: u64) {
    self.graph.subscribe_node(
      &mut auto_commit(&mut self.connection),
      &mut ObjectGraphAggregator {
        node_aggregator: &mut self.node_aggregator,
        edge_aggregator: &mut self.edge_aggregator,
        backedge_aggregator: &mut self.backedge_aggregator,
      },
      id,
      port,
    );
  }

  pub fn unsubscribe_node(&mut self, id: u128, port: u64) {
    self.graph.unsubscribe_node(id, port);
  }
}
