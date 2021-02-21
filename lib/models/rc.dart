class RC {
  int row;
  int col;

  RC({this.row, this.col});

  /// Swap the row and column values. Can be used to swap landscape coordinates
  /// to portrait.
  void swap() {
    int i = row;
    row = col;
    col = i;
  }

  @override
  String toString() {
    return 'RC{row: $row, col: $col}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RC &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}