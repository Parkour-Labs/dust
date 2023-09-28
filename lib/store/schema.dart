class Schema {
  bool initialized = false;
  final List<int> stickyNodes;
  final List<int> stickyAtoms;
  final List<int> stickyEdges;
  final List<int> acyclicEdges;

  Schema({
    required this.stickyNodes,
    required this.stickyAtoms,
    required this.stickyEdges,
    required this.acyclicEdges,
  });
}
