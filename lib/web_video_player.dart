import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:http/http.dart' as http;

class WebVideoPlayer extends StatefulWidget {
  const WebVideoPlayer({super.key});

  @override
  WebVideoPlayerState createState() => WebVideoPlayerState();
}

class WebVideoPlayerState extends State<WebVideoPlayer> {
  RxBool isLoading = false.obs;
  RxBool hasDataFounded = false.obs;
  RxList<String> playableUrls = <String>[].obs;
  RxInt currentPlayerIndex = 0.obs;
  RxBool videoIsLoaded = false.obs;
  RxString title = "".obs;
  RxBool isMovie = true.obs;
  RxList<Map<String, dynamic>> listOfMovie = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> filteredList = <Map<String, dynamic>>[].obs;

  Player player = Player();
  VideoController? controller;

  @override
  void initState() {
    super.initState();
    controller = VideoController(player);
    setUpData();
  }

  void searchItems(String query) {
    filteredList.value = listOfMovie.where((item) {
      return (item['mn'] as String).toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Method to highlight the search term in the list item
  TextSpan highlightText(String text, String query) {
    List<TextSpan> spans = [];
    int start = 0;
    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();

    while (start < text.length) {
      int index = lowerText.indexOf(lowerQuery, start);

      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      // Add text before the match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      // Highlight the match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(backgroundColor: Colors.yellow),
      ));

      start = index + query.length;
    }

    return TextSpan(children: spans);
  }

  setUpData() async {
    String url = html.window.location.href;
    // Create a Uri object from the current URL
    Uri uri = Uri.parse(url);
    isLoading.value = true;
    final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/zsaergddtgdgt/ksnvbhsbvujcadgbvui/refs/heads/master/test.json'));
    Map<String, dynamic> data = json.decode(response.body);
    isLoading.value = false;
    if (data.containsKey('AllMovieDataList')) {
      for (var e in (data['AllMovieDataList'] as List)) {
        listOfMovie.add(e);
        filteredList.add(e);
      }
      if (uri.queryParameters.containsKey('id')) {
        String videoId = "${uri.queryParameters['id']}";
        if (uri.queryParameters.containsKey('isMovie') &&
            (uri.queryParameters['isMovie'] as String) == "true") {
          isMovie.value = true;
          // load Movie using id
          Map<String, dynamic> movieObject = (data['AllMovieDataList'] as List)
              .firstWhere((element) => (element as Map)['id'] == videoId,
                  orElse: () => {});
          if (movieObject.isNotEmpty) {
            if (movieObject.containsKey('mn')) title.value = movieObject['mn'];
            bool isHd = uri.queryParameters.containsKey('hd') &&
                (uri.queryParameters['hd'] as String) == "true";
            List<String> hdArray = [
              "${movieObject['s1']}",
              "${movieObject['s2']}",
              "${movieObject['s3']}",
              "${movieObject['s4']}"
            ];
            hdArray.removeWhere((element) =>
                element == "FALSE" || element == '' || element == '.mkv.mp4');
            List<String> nonHdArray = [
              "${movieObject['4s1']}",
              "${movieObject['4s2']}",
              "${movieObject['4s3']}",
              "${movieObject['4s4']}"
            ];
            nonHdArray.removeWhere((element) =>
                element == "FALSE" || element == '' || element == '.mkv.mp4');
            playableUrls.value = isHd == true
                ? hdArray
                : (movieObject.containsKey('480p') &&
                        movieObject['480p'] == "TRUE")
                    ? nonHdArray
                    : hdArray;
            String playableUrl = playableUrls[currentPlayerIndex.value];
            if (playableUrl.isNotEmpty) {
              hasDataFounded.value = true;
              setUpFlickManager(playableUrl);
            } else {
              hasDataFounded.value = false;
            }
          } else {
            hasDataFounded.value = false;
          }
        } else {
          hasDataFounded.value = false;
        }
      } else {
        hasDataFounded.value = false;
      }
    } else {
      hasDataFounded.value = false;
    }
  }

  setUpFlickManager(String url) {
    print(url);
    player.open(Media(url)).then((value) {
      if (hasDataFounded.value) {
        videoIsLoaded.value = true;
      }
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          return Text(title.value);
        }),
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search...',
                  border: OutlineInputBorder(),
                ),
                onChanged: searchItems,
              ),
            ),
            Expanded(
              child: Obx(() {
                return ListView.builder(
                  itemBuilder: (context, index) => GestureDetector(
                    child: ListTile(
                      title: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            filteredList[index]['mn'],
                            style: const TextStyle(color: Colors.white),
                          )),
                    ),
                    onTap: () async {
                      String movieUrl =
                          'https://umeshkanhasoft.github.io/web_app/?id=${filteredList[index]['id']}&isMovie=true';
                      js.context.callMethod('open', [movieUrl]);
                    },
                  ),
                  itemCount: filteredList.length,
                );
              }),
            ),
          ],
        ),
      ),
      body: Obx(() {
        return isLoading.value && videoIsLoaded.value == false
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 1.0,
                ),
              )
            : hasDataFounded.value
                ? Video(controller: controller!)
                : const Center(
                    child: Text(
                        style: TextStyle(fontSize: 25),
                        textAlign: TextAlign.center,
                        "No video found please try after some time... or may be your url is wrong please try with valid URL..."),
                  );
      }),
    );
  }
}
