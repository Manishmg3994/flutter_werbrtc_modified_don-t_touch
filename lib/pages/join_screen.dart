import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:snippet_coder_utils/FormHelper.dart';

import 'package:videocallwebrtc/models/meeting_details.dart';
import 'package:videocallwebrtc/pages/meeting_page.dart';

import '../api/meeting_api.dart';

class JoinScreen extends StatefulWidget {
  final MeetingDetail? meetingDetails;
  final bool? isHost;

  const JoinScreen({Key? key, this.meetingDetails, this.isHost})
      : super(key: key);

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  static final GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  String userName = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Join Meeting"),
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
            const SizedBox(height: 20),
            FormHelper.inputFieldWidget(context, "UserId", "Enter your Name ",
                (val) {
              if (val.isEmpty) {
                return "Name is required and can't be empty";
              }
              return null;
            }, (onSaved) {
              userName = onSaved;
            }, onChange: (onChange) {
              userName = onChange;
            },
                borderRadius: 10,
                borderFocusColor: Colors.redAccent,
                borderColor: Colors.redAccent,
                hintColor: Colors.grey),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Flexible(
                  child: FormHelper.submitButton("Join Meeting", () async {
                if (widget.isHost!) {
                  var response = await startMeeting(hostName: userName);
                  final body = json.decode(response!.body);
                  final meetId = body["data"];
                  validateMeeting(meetId);
                } else {
                  goToMeetingScreen(widget.meetingDetails);
                }
              })),
            ])
          ],
        ),
      ),
    );
  }

  void validateMeeting(String meetingId) async {
    try {
      Response? response =
          await joinMeeting(meetingId); //here in response is var
      var data = json.decode(response!.body);
      final meetingDetails = MeetingDetail.fromJson(data["data"]);
      goToMeetingScreen(widget.meetingDetails ?? meetingDetails);
    } catch (err) {
      FormHelper.showSimpleAlertDialog(
          context, "Meeting App", "Invalid Meeting Id", "OK", () {
        Navigator.of(context).pop();
      });
    }
  }

  goToMeetingScreen(MeetingDetail? meetingDetails) async {
    if (validateAndSave()) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) {
          return MeetingPage(
            meetingId: meetingDetails!.id,
            name: userName,
            meetingDetail: meetingDetails,
          );
        },
      ));
    }
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
