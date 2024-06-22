class Song {
  final String name;
  final List<String> artists;

  Song({required this.name, required this.artists});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'artists': artists.join(', '), // Join artists list into a single string
    };
  }
}
