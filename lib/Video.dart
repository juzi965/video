class Video {
  final String avatar;
  final String created;
  final String type;
  final String username;
  final String video;

  const Video(
      {this.avatar, this.created, this.type, this.username, this.video});
  factory Video.fromJson(Map<String, dynamic> json) {
    return new Video(
        avatar: json['avatar'],
        created: json['created_at'],
        type: json['type'],
        username: json['username'],
        video: json['video']);
  }
}
