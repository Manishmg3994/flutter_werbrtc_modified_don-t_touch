import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:snippet_coder_utils/FormHelper.dart';
import 'package:videocallwebrtc/api/meeting_api.dart';
import 'package:videocallwebrtc/models/meeting_details.dart';

import 'join_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isHost = false;
  static final GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  String meetingId = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting App'),
        backgroundColor: Colors.redAccent,
      ),
      body: Form(
        key: globalKey,
        child: formUI(),
      ),
    );
  }

  formUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome to WebRTC Meeting App",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontSize: 25),
            ),
            const SizedBox(height: 20),
            FormHelper.inputFieldWidget(
                context, "meetingId", "Enter your Meeting Id", (val) {
              if (val.isEmpty) {
                return "Meeting Id is required and can't be empty";
              }
              return null;
            }, (onSaved) {
              meetingId = onSaved;
            },
                borderRadius: 10,
                borderFocusColor: Colors.redAccent,
                borderColor: Colors.redAccent,
                hintColor: Colors.grey),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Flexible(
                  child: FormHelper.submitButton("Join Meeting", () {
                isHost = false;
                if (validateAndSave()) {
                  validateMeeting(meetingId: meetingId, isHost: isHost);
                }
              })),
              Flexible(
                  child: FormHelper.submitButton("Start Meeting", () async {
                isHost = true;
                goToJoinScreen(isHost: isHost);
              }))
            ])
          ],
        ),
      ),
    );
  }

  void validateMeeting({String? meetingId, required bool isHost}) async {
    try {
      Response? response =
          await joinMeeting(meetingId!); //here in response is var
      var data = json.decode(response!.body);
      final meetingDetails = MeetingDetail.fromJson(data["data"]);
      goToJoinScreen(meetingDetail: meetingDetails, isHost: isHost);
    } catch (err) {
      FormHelper.showSimpleAlertDialog(
          context, "Meeting App", "Invalid Meeting Id", "OK", () {
        Navigator.of(context).pop();
      });
    }
  }

  goToJoinScreen({MeetingDetail? meetingDetail, required bool isHost}) async {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => JoinScreen(
                  meetingDetails: meetingDetail,
                  isHost: isHost,
                )));
  }

  bool validateAndSave() {
    final form = globalKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }
}
