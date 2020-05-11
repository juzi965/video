import 'dart:convert';
import 'dart:io';

import 'package:awsome_video_player/awsome_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:http/http.dart' as Http;
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video/Video.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.lightBlue[600],
          accentColor: Colors.cyan[600],
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Video> _videos;
  Future _initFuture;
  bool _isFull;
  int _page;
  String _path;

  @override
  void initState() {
    super.initState();
    _videos = List();
    _isFull = false;
    _page = 0;
    FlutterDownloader.initialize();
    _initFuture = _getVideos();
  }

  Future _getVideos() async {
    var response = await Http.get("http://api.899.mn/api/api?page=$_page");
    List list = jsonDecode(response.body.toString())['data'];
    setState(() {
      _videos.addAll(list.map((v) => Video.fromJson(v)).toList());
      _videos.removeWhere((v) => v.type != 'video');
    });
  }

  Future<String> _findLocalPath() async {
    //这里根据平台获取当前安装目录
    final directory = Theme.of(context).platform == TargetPlatform.android
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    return directory.path;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.transparent));
    SystemChrome.setEnabledSystemUIOverlays([]);
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: PreferredSize(
          child: Offstage(
            offstage: true,
            child: AppBar(
              title: Text("视频"),
              backgroundColor: Colors.transparent,
              centerTitle: true,
              elevation: 0,
            ),
          ),
          preferredSize:
              Size.fromHeight(MediaQuery.of(context).size.height * 0.07),
        ),
        body: Container(
            child: FutureBuilder(future: _initFuture, builder: _bulidFuture)));
  }

  Widget _bulidFuture(BuildContext context, AsyncSnapshot snapshot) {
    switch (snapshot.connectionState) {
      case ConnectionState.none:
      case ConnectionState.active:
      case ConnectionState.waiting:
        return Container(
            alignment: Alignment.center, child: CircularProgressIndicator());
      case ConnectionState.done:
        if (snapshot.hasError) {
          return Container(alignment: Alignment.center, child: Text('网络请求出错'));
        }
        return _swiperBuilder();
      default:
        return null;
    }
  }

  Widget _swiperBuilder() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
      child: Swiper(
        loop: false,
        itemBuilder: _bulidVideo,
        itemCount: _videos.length,
        scrollDirection: Axis.vertical,
        onIndexChanged: _indexChanged,
      ),
    );
  }

  Widget _bulidVideo(BuildContext context, int index) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        Positioned.fill(
          top: 0.0,
          left: 0.0,
          right: 0.0,
          child: AwsomeVideoPlayer(
            _videos[index].video,
            onfullscreen: _onfullscreen,
            onvolume: _onvolume,
            onbrightness: _onbrightness,
            playOptions: VideoPlayOptions(
                loop: true,
                aspectRatio: 16 / 9,
                autoplay: true,
                allowScrubbing: true,
                brightnessGestureUnit: 0.01,
                volumeGestureUnit: 0.01),
            videoStyle: VideoStyle(
              playIcon: Icon(
                Icons.play_circle_outline,
                size: 60,
                color: Colors.white,
              ),
              videoTopBarStyle: VideoTopBarStyle(show: false),
              videoControlBarStyle: VideoControlBarStyle(
                height: 40,
                timeFontSize: 10,
                padding: EdgeInsets.all(5.0),
                fullscreenIcon: Icon(
                  Icons.fullscreen,
                  size: 30,
                  color: Colors.white,
                ),
                fullscreenExitIcon: Icon(
                  Icons.fullscreen_exit,
                  size: 30,
                  color: Colors.white,
                ),
                itemList: ["progress", "time", "fullscreen"],
                progressStyle: VideoProgressStyle(bufferedColor: Colors.white),
              ),
            ),
          ),
        ),
        Positioned(
          height: 600,
          width: 150,
          child: Container(
            color: Colors.transparent,
          ),
        ),
        Positioned(
          bottom: 50.0,
          left: 0.0,
          right: 0.0,
          child: Offstage(
              offstage: _isFull ? true : false,
              child: Container(
                child: ListTile(
                  leading: ClipOval(
                    child: Image.network(
                      _videos[index].avatar,
                      height: 50.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    "@${_videos[index].username}",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  subtitle: Text(
                    _videos[index].created,
                    style: TextStyle(fontSize: 14.0),
                  ),
                  trailing: Icon(Icons.file_download),
                  onTap: () => _download(_videos[index].video),
                ),
              )),
        )
      ],
    );
  }

  void _indexChanged(int index) {
    if (_videos.length <= 2) {
      setState(() {
        _page++;
      });
      _getVideos();
    } else if (index == _videos.length - 2) {
      setState(() {
        _page++;
      });
      _getVideos();
    }
  }

  void _download(String url) async {
    _path = (await _findLocalPath()) + '/Download';
    bool hasExisted = await Directory(_path).exists();
    if (!hasExisted) {
      Directory(_path).create();
    }
    await FlutterDownloader.enqueue(
        url: url,
        savedDir: _path,
        showNotification: true,
        openFileFromNotification: true);
    showToast("视频已开始下载，请在通知栏查看。");
  }

  VideoCallback<bool> _onfullscreen(bool isFull) {
    setState(() {
      _isFull = !_isFull;
    });
  }

  VideoCallback<double> _onvolume(double volume) {
    showToast("音量${(volume * 100).toStringAsFixed(0)}%");
  }

  VideoCallback<double> _onbrightness(double bright) {
    showToast("亮度${(bright * 100).toStringAsFixed(0)}%");
  }

  @override
  void dispose() {
    super.dispose();
  }
}
