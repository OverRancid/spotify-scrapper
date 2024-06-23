class Song {
  final String name;
  final List<String> artists;
  String image = '';
  String ytID = '';

  Song({required this.name, required this.artists, this.image = ''});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'artists': artists.join(', '), // Join artists list into a single string
    };
  }
}
