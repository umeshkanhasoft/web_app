import 'dart:convert';

import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:video_player/video_player.dart';
import 'package:web_app/web_video_control.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'js/facebook_ads.dart';

import 'data_manager.dart';

class WebVideoPlayer extends StatefulWidget {
  const WebVideoPlayer({super.key});

  @override
  WebVideoPlayerState createState() => WebVideoPlayerState();
}

class WebVideoPlayerState extends State<WebVideoPlayer> {
  late FlickManager flickManager;
  late DataManager? dataManager;
  RxBool isLoading = false.obs;
  RxBool hasDataFounded = false.obs;
  RxList<String> playableUrls = <String>[].obs;
  RxInt currentPlayerIndex = 0.obs;
  RxBool videoIsLoaded = false.obs;
  VideoPlayerController? videoPlayerController;

  @override
  void initState() {
    super.initState();
    setUpData();
  }

  setUpData() async {
    isLoading.value = true;
    String url = html.window.location.href;
    // Create a Uri object from the current URL
    Uri uri = Uri.parse(url);
    if (uri.queryParameters.containsKey('id')) {
      String videoId = "${uri.queryParameters['id']}";
      if (uri.queryParameters.containsKey('isMovie') &&
          (uri.queryParameters['isMovie'] as String) == "true") {
        // load Movie using id
        final response = await http.get(Uri.parse(
            'https://raw.githubusercontent.com/zsaergddtgdgt/ksnvbhsbvujcadgbvui/refs/heads/master/test.json'));
        Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('AllMovieDataList')) {
          Map<String, dynamic> movieObject = (data['AllMovieDataList'] as List)
              .firstWhere((element) => (element as Map)['id'] == videoId,
                  orElse: () => {});
          print(uri.queryParameters.containsKey('hd'));
          if (movieObject.isNotEmpty) {
            bool isHd = uri.queryParameters.containsKey('hd') &&
                (uri.queryParameters['hd'] as String) == "true";
            List<String> hdArray = [
              "${movieObject['s1']}",
              "${movieObject['s2']}",
              "${movieObject['s3']}",
              "${movieObject['s4']}"
            ];
            List<String> nonHdArray = [
              "${movieObject['4s1']}",
              "${movieObject['4s2']}",
              "${movieObject['4s3']}",
              "${movieObject['4s4']}"
            ];
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
        // load web series using Main-Id
      }
    } else {
      hasDataFounded.value = false;
    }
    isLoading.value = false;
  }

  setUpFlickManager(String url) {
    // print("<><>asdsadas");
    // onRewardedAdCompleted(() {
    //   print('Rewarded ad completed!');
    // });
    //
    // loadRewardedAd();

    // Set up the ad completion listener
    /* onRewardedAdCompleted(() {
      videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize()
        ..addListener(
          () {
            // if (videoPlayerController?.value.hasError == true) {
            //   hasDataFounded.value = false;
            //   if (currentPlayerIndex.value < 4) {
            //     currentPlayerIndex.value = currentPlayerIndex.value + 1;
            //     videoPlayerController?.dispose();
            //     setUpFlickManager(playableUrls[currentPlayerIndex.value]);
            //     setState(() {});
            //   }
            // }
          },
        );

      if (hasDataFounded.value) {
        flickManager = FlickManager(
            videoPlayerController: videoPlayerController!,
            autoPlay: true,
            autoInitialize: true);
        dataManager = DataManager(flickManager: flickManager, urls: []);
        videoIsLoaded.value = true;
      }
    });*/

    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize()
      ..addListener(
        () {
          // if (videoPlayerController?.value.hasError == true) {
          //   hasDataFounded.value = false;
          //   if (currentPlayerIndex.value < 4) {
          //     currentPlayerIndex.value = currentPlayerIndex.value + 1;
          //     videoPlayerController?.dispose();
          //     setUpFlickManager(playableUrls[currentPlayerIndex.value]);
          //     setState(() {});
          //   }
          // }
        },
      );

    if (hasDataFounded.value) {
      flickManager = FlickManager(
          videoPlayerController: videoPlayerController!,
          autoPlay: true,
          autoInitialize: true);
      dataManager = DataManager(flickManager: flickManager, urls: []);
      videoIsLoaded.value = true;
    }
  }

  @override
  void dispose() {
    flickManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        return isLoading.value && videoIsLoaded.value == false
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 1.0,
                ),
              )
            : hasDataFounded.value
                ? VisibilityDetector(
                    key: ObjectKey(flickManager),
                    onVisibilityChanged: (visibility) {
                      if (visibility.visibleFraction == 0 && mounted) {
                        flickManager.flickControlManager?.autoPause();
                      } else if (visibility.visibleFraction == 1) {
                        flickManager.flickControlManager?.autoResume();
                      }
                    },
                    child: FlickVideoPlayer(
                      flickManager: flickManager,
                      flickVideoWithControls: FlickVideoWithControls(
                        controls: WebVideoControl(
                          dataManager: dataManager!,
                          iconSize: 30,
                          fontSize: 14,
                          progressBarSettings: FlickProgressBarSettings(
                            height: 5,
                            handleRadius: 5.5,
                          ),
                        ),
                        videoFit: BoxFit.contain,
                        // aspectRatioWhenLoading: 4 / 3,
                      ),
                    ),
                  )
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
