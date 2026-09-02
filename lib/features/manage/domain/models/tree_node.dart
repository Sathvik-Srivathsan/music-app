class TreeNode {
  final int id;
  final String name;
  final List<TreeNode> children;
  final int descendantCount;

  TreeNode({
    required this.id,
    required this.name,
    this.children = const [],
    this.descendantCount = 0,
  });

  bool get hasChildren => children.isNotEmpty;
}
