part of '../store.dart';

class Backlinks<T extends Object> extends Node implements Observable<List<T>> {
  final Repository<T> repository;
  final Id dst;
  final int label;
  final Set<(Id, Id)> edges = {};

  Backlinks._(this.repository, this.dst, this.label);

  @override
  List<T> get(Node? ref) {
    register(ref);
    return edges.map<T>((elem) => repository.get(elem.$2)!).toList();
  }

  void _insert(Id id, Id src) {
    edges.add((id, src));
    notify();
  }

  void _remove(Id id, Id src) {
    edges.remove((id, src));
    notify();
  }
}
