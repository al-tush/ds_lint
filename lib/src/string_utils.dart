String unescapeStr(String s) {
  return s
      .replaceAllMapped(RegExp(r'\\u([0-9A-Fa-f]{4})'), (Match match) {
    return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
  })
      .replaceAllMapped(RegExp(r'\\x([0-9A-Fa-f]{2})'), (Match match) {
    return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
  })
      .replaceAll(r'\t', '\t')
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\r', '\r')
      .replaceAll(r'\\', '\\')
      .replaceAll(r'\"', '\"')
      .replaceAll(r"\'", "\'");
}
