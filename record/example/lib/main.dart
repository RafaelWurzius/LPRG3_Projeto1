import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import 'package:record_example/audio_player.dart';

void main() => runApp(const MyApp());

class AudioRecorder extends StatefulWidget {
  final void Function(String path) onStop;

  const AudioRecorder({Key? key, required this.onStop}) : super(key: key);

  @override
  _AudioRecorderState createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  int _recordDuration = 0;
  Timer? _timer;
  final _audioRecorder = Record();

  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Amplitude? _amplitude;

  @override
  void initState() {
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      setState(() => _recordState = recordState);
    });

    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) => setState(() => _amplitude = amp));

    super.initState();
  }

  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
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
      widget.onStop(path);
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
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildRecordStopControl(),
                const SizedBox(width: 20),
                _buildPauseResumeControl(),
                const SizedBox(width: 20),
                _buildText(),
              ],
            ),
            // if (_amplitude != null) ...[
            //   // const SizedBox(height: 40),
            //   // Text('Current: ${_amplitude?.current ?? 0.0}'),
            //   // Text('Max: ${_amplitude?.max ?? 0.0}'),
            // ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;

    if (_recordState != RecordState.stop) {
      icon = const Icon(Icons.stop,
          color: Color.fromARGB(255, 205, 146, 255), size: 30);
      color = Color.fromARGB(255, 205, 146, 255).withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon =
          Icon(Icons.mic, color: Color.fromARGB(255, 205, 146, 255), size: 30);
      color = Color.fromARGB(255, 205, 146, 255).withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
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
      icon = const Icon(Icons.pause,
          color: Color.fromARGB(255, 205, 146, 255), size: 30);
      color = Color.fromARGB(255, 205, 146, 255).withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = const Icon(Icons.play_arrow,
          color: Color.fromARGB(255, 205, 146, 255), size: 30);
      color = Color.fromARGB(255, 205, 146, 255).withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            if (_recordState == RecordState.pause) {
              _resume();
            } else {
              _pause();
            }
          },
        ),
      ),
    );
  }

  Widget _buildText() {
    if (_recordState != RecordState.stop) {
      return _buildTimer();
    }

    return const Text("Waiting to record");
  }

  // Lista de músicas
  // Widget _buildList(BuildContext context) {
  //   int songId = 0;

  //   return Scaffold(
  //     body: ListView(
  //       children: <Widget>[
  //         ListTile(
  //           // leading: Icon(Icons.map),
  //           leading: Image.network(
  //             'https://i.ytimg.com/vi/L_jWHffIx5E/hqdefault.jpg',
  //             height: 100,
  //             width: 100,
  //           ),
  //           title: Text('Smash Mouth - All Star'),
  //           onTap: () => songId = 1,
  //         ),
  //         ListTile(
  //           // leading: Icon(Icons.photo_album),
  //           leading: Image.network(
  //             'https://i.pinimg.com/564x/8d/59/cc/8d59cc084ce0c51592475cfefe9895b0.jpg',
  //             height: 100,
  //             width: 100,
  //           ),
  //           title: Text('Renai Circulation'),
  //           onTap: () => songId = 2,
  //         ),
  //         ListTile(
  //           // leading: Icon(Icons.phone),
  //           leading: Image.network(
  //             'https://www.rbsdirect.com.br/filestore/6/8/7/8/2/2/4_17fd53b9d5fb8d5/4228786_2906accc8113729.jpg?w=700',
  //             height: 100,
  //             width: 100,
  //           ),
  //           title: Text('Toguro Theme'),
  //           onTap: () => songId = 3,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: const TextStyle(color: Color.fromARGB(255, 205, 146, 255)),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0' + numberStr;
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

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showPlayer = false;
  String? audioPath;

  @override
  void initState() {
    showPlayer = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: showPlayer
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: AudioPlayer(
                    source: audioPath!,
                    onDelete: () {
                      setState(() => showPlayer = false);
                    },
                  ),
                )
              : AudioRecorder(
                  onStop: (path) {
                    if (kDebugMode) print('Recorded file path: $path');
                    setState(() {
                      audioPath = path;
                      showPlayer = true;
                    });
                  },
                ),
        ),
      ),
    );
  }
}
