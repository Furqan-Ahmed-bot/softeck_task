// ignore_for_file: prefer_const_constructors

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:record/record.dart';
import 'dart:async';

class AudioRecorder extends StatefulWidget {


  const AudioRecorder({Key? key, }) : super(key: key);

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  int _recordDuration = 0;
  Timer? _timer;
  final _audioRecorder = Record();
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;

  bool _isResumed = false;

  List<dynamic> files = [];

  void audiopath(audioPath) async {
    if (audioPath != null) {
      files.add(<String, dynamic>{
        "name":
            'rec ${DateFormat('yyyy-MM-dd h:mm').format(DateTime.now())}.mp3',
        "path": audioPath
      });
    }
  }

  @override
  void initState() {
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      setState(() => _recordState = recordState);
    });

    super.initState();
  }

  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // We don't do anything with this but printing
        final isSupported = await _audioRecorder.isEncoderSupported(
          AudioEncoder.aacLc,
        );
        if (kDebugMode) {
          print('${AudioEncoder.aacLc.name} supported: $isSupported');
        }

        await _audioRecorder.start();
        _recordDuration = 0;

        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _recordDuration = 0;

    final path = await _audioRecorder.stop();

    if (path != null) {

      audiopath(path);
    }
  }

  Future<void> _pause() async {
    _timer?.cancel();
    await _audioRecorder.pause();
  }

  Future<void> _resume() async {
    _startTimer();
    await _audioRecorder.resume();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            height: 60,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 45),
                child: _buildRecordStopControl(),
              ),
              const SizedBox(width: 20),
              if (_isResumed == false) ...[
                _buildPauseResumeControl(),
              ],
              const SizedBox(width: 20),
              _buildText(),
            ],
          ),
          if (files.isNotEmpty) ...[
           const SizedBox(
              height: 50,
            ),
          const  Text('Audio Recordings'),
            Padding(
                padding: const EdgeInsets.fromLTRB(30, 10, 30, 0),
                child: Container(
                  height: files.length > 5 ? 280 : files.length * 45.0,
                  decoration: BoxDecoration(border: Border.all()),
                  child: ListView.builder(
                      shrinkWrap: true,
                      reverse: true,
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.lightBlueAccent,
                                  borderRadius: BorderRadius.circular(10)),
                              height: 30,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 5,
                                  ),
                                  InkWell(
                                      onTap: () {
                                        OpenFile.open(files[index]['path']);
                                      },
                                      child: Text(files[index]['name'])),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Spacer(),
                                  InkWell(
                                      onTap: () {
                                        setState(() {
                                          files.removeAt(index);
                                        });

                          
                                      },
                                      child: Icon(Icons.delete_outline))
                                ],
                              )),
                        );
                      }),
                ))
          ]
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;

    if (_recordState != RecordState.stop) {
      icon = const Icon(Icons.stop, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.mic, color: theme.primaryColor, size: 90);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: GestureDetector(
          onLongPress: () {
            _isResumed = true;
            _start();
          },
          onLongPressUp: () {
            _isResumed = false;
            _stop();
          },
          child: SizedBox(width: 120, height: 120, child: icon),
          onTap: () {
            (_recordState != RecordState.stop) ? _stop() : _start();
          },
        ),
      ),
    );
  }

  Widget _buildPauseResumeControl() {
    if (_recordState == RecordState.stop) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    if (_recordState == RecordState.record) {
      icon = const Icon(Icons.pause, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = const Icon(Icons.play_arrow, color: Colors.red, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 100, height: 100, child: icon),
          onTap: () {
            (_recordState == RecordState.pause) ? _resume() : _pause();
          },
        ),
      ),
    );
  }

  Widget _buildText() {
    if (_recordState != RecordState.stop) {
      return _buildTimer();
    }

    return SizedBox();
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: const TextStyle(color: Colors.red),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }
}
