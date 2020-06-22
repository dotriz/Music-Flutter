import 'dart:io';
import 'dart:ui';
import "package:flutter/material.dart";
import "package:flutter/animation.dart";

import 'package:Music/constants.dart';
import 'package:Music/models/models.dart';
import 'package:Music/helpers/db.dart';
import 'package:Music/helpers/generateSubtitle.dart';
import 'package:Music/routes/widgets/SongView.dart';

class AlbumPage extends StatefulWidget {
  final Album album;

  const AlbumPage(this.album, {Key key}) : super(key: key);

  @override
  _AlbumPageState createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage>
    with SingleTickerProviderStateMixin {
  List<Song> _songs = [];
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    beginAnimation();
    getSongs();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Future<void> beginAnimation() async {
    // TODO change this to constant variable for Custom page transition
    await Future.delayed(const Duration(milliseconds: 450));
    await _controller.forward();
  }

  Future<void> getSongs() async {
    var db = await getDB();

    var songs = Song.fromMapArray(await db.query(
      Tables.Songs,
      where: "albumId LIKE ?",
      whereArgs: [widget.album.id],
      orderBy: "LOWER(title), title",
    ));

    if (!mounted) return;

    setState(() {
      _songs = songs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).backgroundColor,
      child: Column(
        children: <Widget>[
          AlbumCover(
            album: widget.album,
            controller: _controller,
          ),
          SizedBox(height: 30),
          Expanded(
            child: AnimatedSongView(
              controller: _controller,
              delay: 0.5,
              length: 0.5,
              songs: _songs,
              isLocal: true,
              onClick: (song, i) {
                print(song);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AlbumCover extends StatelessWidget {
  final Album album;
  final AnimationController controller;
  final Animation<double> _animation1;
  final Animation<double> _animation2;

  AlbumCover({Key key, @required this.album, @required this.controller})
      : _animation1 = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: controller,
          curve: Interval(0.0, 0.5, curve: Curves.easeOutCubic),
        )),
        _animation2 = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: controller,
          curve: Interval(0.25, 0.75, curve: Curves.easeOutCubic),
        )),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Stack(
        overflow: Overflow.visible,
        children: [
          Hero(
            tag: album.id,
            child: Image.file(
              File(album.imagePath),
              width: screenWidth,
              height: screenWidth,
            ),
          ),
          Opacity(
            opacity: _animation1.value,
            child: Container(
              width: screenWidth,
              height: screenWidth,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).backgroundColor.withOpacity(0.2),
                    Theme.of(context).backgroundColor.withOpacity(0.2),
                    Theme.of(context).backgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Opacity(
            opacity: _animation2.value,
            child: SafeArea(
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: Navigator.of(context).pop,
              ),
            ),
          ),
          Opacity(
            opacity: _animation1.value,
            child: SizedBox(
              height: screenWidth,
              width: screenWidth,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      height: screenWidth / 4,
                    ),
                    Container(
                      constraints: BoxConstraints(maxWidth: 0.8 * screenWidth),
                      child: Text(
                        album.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headline1,
                      ),
                    ),
                    Text(
                      generateSubtitle(
                        type: "Album",
                        artist: album.artist,
                      ),
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -2 * rem,
            left: 0.2 * screenWidth,
            width: 0.6 * screenWidth,
            child: Opacity(
              opacity: _animation2.value,
              child: ButtonBar(
                buttonHeight: 2.5 * rem,
                buttonMinWidth: 0.25 * screenWidth,
                alignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FlatButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(1.25 * rem)),
                    color: Theme.of(context).buttonColor,
                    onPressed: () {},
                    child: Text("Play All"),
                  ),
                  FlatButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(1.25 * rem)),
                    color: Theme.of(context).buttonColor,
                    onPressed: () {},
                    child: Text("Play Random"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
