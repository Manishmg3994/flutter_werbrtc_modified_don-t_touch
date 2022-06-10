import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc_wrapper/flutter_webrtc_wrapper.dart';
import 'package:path_provider/path_provider.dart';

import 'package:videocallwebrtc/models/meeting_details.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:videocallwebrtc/pages/home_screen.dart';
import 'package:videocallwebrtc/utils/user.utils.dart';
import 'package:videocallwebrtc/widgets/control_panel.dart';
import 'package:videocallwebrtc/widgets/remote_connection.dart';

import '../api/meeting_api.dart';

//TODO stream on get api if 500 then endcall method
class MeetingPage extends StatefulWidget {
  final String? meetingId;
  final String? name;
  final MeetingDetail meetingDetail;

  const MeetingPage(
      {Key? key,
      this.meetingId,
      this.name,
      required this.meetingDetail}) //metingDetail.hostId requred to delete mongos document
      : super(key: key);

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  final _localRenderer = RTCVideoRenderer();
  //this is local person video view
  MediaStream? localStream;
  final Map<String, dynamic> mediaConstraints = {
    "audio": true,
    "video": true
  }; //'video':{'facingMode':'user'} or
  //'video': {
  //   'mandatory': {
  //     'minWidth':
  //         '640', // Provide your own width, height and frame rate here
  //     'minHeight': '480',
  //     'minFrameRate': '30',
  //   },
  //   'facingMode': 'user',
  //   'optional': [],
  // }
  bool isConnectionFailed = false;
  //start
  MediaRecorder? _mediaRecorder;
  bool get _isRec => _mediaRecorder != null;
  WebRTCMeetingHelper? meetingHelper;
  bool _inCalling = false;
  bool _isTorchOn = false;

  List<MediaDeviceInfo>? _mediaDevicesList;
  //end
  void startMeeting() async {
    final String userId = await loadUserId(); //TODO CHANGE FOR FIRESTORE
    meetingHelper = WebRTCMeetingHelper(
      url:
          "http://127.0.0.1:5000", // TODO change is requred everytime for new host for windowsuse 127 and for android use 10.0.2 ank make sure use ing proxy setup for android by uing emulator
      meetingId: widget.meetingDetail.id,
      userId: userId,
      name: widget.name,
    );
    localStream = await navigator.mediaDevices
        .getUserMedia(mediaConstraints); //stream is localStream
    _mediaDevicesList = await navigator.mediaDevices.enumerateDevices();
    _localRenderer.srcObject = localStream;
    meetingHelper!.stream = localStream;
    meetingHelper!.on(
      "open",
      context,
      (ev, context) {
        setState(() {
          isConnectionFailed = false;
        });
      },
    );
    meetingHelper!.on(
      "connection",
      context,
      (ev, context) {
        setState(() {
          isConnectionFailed = false;
        });
      },
    );
    meetingHelper!.on(
      "user-left", //TODO ither operation to do if any meeting member left the video cal or meeeting ,as to show popup saying perticular person have left the meeting or snakbar
      context,
      (ev, context) {
        setState(() {
          isConnectionFailed = false;
        });
      },
    );
    meetingHelper!.on(
      "video-toggle",
      context,
      (ev, context) {
        setState(() {});
      },
    );
    meetingHelper!.on(
      "audio-toggle",
      context,
      (ev, context) {
        setState(() {});
      },
    );
    meetingHelper!.on(
      "meeting-ended",
      context,
      (ev, context) {
        onMeetingEnd(); //TODO firebase delete Document
      },
    );
    meetingHelper!.on(
      "connection-setting-changed",
      context,
      (ev, context) {
        setState(() {
          isConnectionFailed = false;
        });
      },
    );
    meetingHelper!.on(
      "stream-changed",
      context,
      (ev, context) {
        setState(() {
          isConnectionFailed = false;
        });
      },
    );
    setState(() {});
  }

  initRenderers() async {
    await _localRenderer.initialize();
  }

  @override
  void initState() {
    super.initState();
    initRenderers();
    startMeeting();
  }

  @override
  void deactivate() {
    super.deactivate();
    _localRenderer.dispose();
    if (meetingHelper != null) {
      meetingHelper!.destroy();
      meetingHelper = null;
    }
  }

  void onMeetingEnd() {
    // deleting firestore data TODO
    if (meetingHelper != null) {
      deleteDocinApi(
          meetingId: widget.meetingId!, hostId: widget.meetingDetail.hostId!);
      meetingHelper!.endMeeting();
      meetingHelper = null;
      goToHomePage();
    }
  }

  void _startRecording() async {
    String? timeFile = DateTime.now().toString();
    if (localStream == null) throw Exception('Stream is not initialized');
    if (Platform.isIOS) {
      print('Recording is not available on iOS');
      return;
    }
    // TODO(rostopira): request write storage permission
    final storagePath = await getExternalStorageDirectory();
    if (storagePath == null) throw Exception('Can\'t find storagePath');

    final filePath = storagePath.path + '/AntinnaRecording/${timeFile}.mp4';
    _mediaRecorder = MediaRecorder();
    setState(() {});

    final videoTrack = localStream!
        .getVideoTracks()
        .firstWhere((track) => track.kind == 'video');
    await _mediaRecorder!.start(
      filePath,
      videoTrack: videoTrack,
    );
  }

  void _stopRecording() async {
    await _mediaRecorder?.stop();
    setState(() {
      _mediaRecorder = null;
    });
  }

  void _toggleTorch() async {
    if (localStream == null) throw Exception('Stream is not initialized');

    final videoTrack = localStream!
        .getVideoTracks()
        .firstWhere((track) => track.kind == 'video');
    final has = await videoTrack.hasTorch();
    if (has) {
      print('[TORCH] Current camera supports torch mode');
      setState(() => _isTorchOn = !_isTorchOn);
      await videoTrack.setTorch(_isTorchOn);
      print('[TORCH] Torch state is now ${_isTorchOn ? 'on' : 'off'}');
    } else {
      print('[TORCH] Current camera does not support torch mode');
    }
  }

  void _toggleCamera() async {
    try {
      if (localStream == null) throw Exception('Stream is not initialized');

      final videoTrack = localStream!
          .getVideoTracks()
          .firstWhere((track) => track.kind == 'video');
      await Helper.switchCamera(videoTrack);
    } catch (error) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomSheet: PopupMenuButton<String>(
        onSelected: _selectAudioOutput,
        itemBuilder: (BuildContext context) {
          if (_mediaDevicesList != null) {
            return _mediaDevicesList!
                .where((device) => device.kind == 'audiooutput')
                .map((device) {
              return PopupMenuItem<String>(
                value: device.deviceId,
                child: Text(device.label),
              );
            }).toList();
          }
          return [];
        },
      ),
      backgroundColor: Colors.black87,
      body: _buildMeetingRoom(),
      bottomNavigationBar: ControlPanel(
        onAudioToggle: onAudioToggle,
        onVideoToggle: onVideoToggle,
        videoEnabled: isVideoEnabled(),
        audioEnabled: isAudioEnabled(),
        isConnectionFailed: isConnectionFailed,
        onReconnect: handleReconnect,
        onMeetingEnd: onMeetingEnd,
        onCameraToggle: _toggleCamera,
      ),
    );
  }

  void onAudioToggle() {
    if (meetingHelper != null) {
      setState(() {
        meetingHelper!.toggleAudio();
      });
    }
  }

  void onVideoToggle() {
    if (meetingHelper != null) {
      setState(() {
        meetingHelper!.toggleVideo();
      });
    }
  }

  void handleReconnect() {
    if (meetingHelper != null) {
      meetingHelper!.reconnect();
    }
  }

  bool isAudioEnabled() {
    return meetingHelper != null ? meetingHelper!.audioEnabled! : false;
  }

  bool isVideoEnabled() {
    return meetingHelper != null ? meetingHelper!.videoEnabled! : false; //
  }

  void goToHomePage() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const HomeScreen()));
  }

  _buildMeetingRoom() {
    return Stack(
      children: [
        meetingHelper != null && meetingHelper!.connections.isNotEmpty
            ? GridView.count(
                crossAxisCount: meetingHelper!.connections.length < 3 ? 1 : 2,
                children:
                    List.generate(meetingHelper!.connections.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.all(1),
                    child: RemoteConnection(
                      renderer: meetingHelper!.connections[index].renderer,
                      connection: meetingHelper!.connections[index],
                    ),
                  );
                }))
            : const Center(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    "Waiting For Participants To Join The Meeting",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 24),
                  ),
                ),
              ),
        //my local view TODO
        Positioned(
          bottom: 10,
          right: 0,
          child: SizedBox(
              width: 150, height: 200, child: RTCVideoView(_localRenderer)),
        ),
      ],
    );
  }

  void _selectAudioOutput(String deviceId) {
    _localRenderer.audioOutput(deviceId);
  }
}
