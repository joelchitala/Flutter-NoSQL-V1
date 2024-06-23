class UnidirectionalChain {
  List<bool Function()> blocks = [];

  UnidirectionalChain addBlock({required bool Function() block}) {
    blocks.add(block);
    return this;
  }

  bool execute() {
    bool results = true;

    for (var block in blocks) {
      results = block();
      if (!results) break;
    }

    return results;
  }
}
