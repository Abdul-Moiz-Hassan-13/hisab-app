import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key, required this.initialCounts});

  final Map<String, int> initialCounts;

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  static const int _maxCount = 300000;
  late final List<String> _prayers;
  late final Map<String, int> _counts;
  late final Map<String, TextEditingController> _controllers;
  bool _isShowingLimitAlert = false;

  @override
  void initState() {
    super.initState();
    _prayers = ['Fajr', 'Zuhr', 'Asr', 'Maghrib', 'Isha', 'Witr'];
    _counts = Map<String, int>.from(widget.initialCounts);
    _controllers = {
      for (final prayer in _prayers)
        prayer: TextEditingController(
          text: (_counts[prayer] ?? 0).toString(),
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showLimitAlert() {
    if (_isShowingLimitAlert) {
      return;
    }

    _isShowingLimitAlert = true;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Limit Reached'),
          content: const Text('Maximum allowed is 300000.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      _isShowingLimitAlert = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        Navigator.pop(context, _counts);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Missed Prayers'),
          centerTitle: true,
          leading: BackButton(onPressed: () => Navigator.pop(context, _counts)),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _prayers.length,
          itemBuilder: (context, index) {
            final prayer = _prayers[index];
            final count = _counts[prayer] ?? 0;
            final controller = _controllers[prayer]!;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(prayer),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: count == 0
                          ? null
                          : () {
                              setState(() {
                                final next = count - 1;
                                _counts[prayer] = next;
                                controller.text = next.toString();
                              });
                            },
                    ),
                    SizedBox(
                      width: 64,
                      child: TextField(
                        controller: controller,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null && parsed > _maxCount) {
                            _showLimitAlert();
                            setState(() {
                              _counts[prayer] = _maxCount;
                              controller.text = _maxCount.toString();
                              controller.selection = TextSelection.collapsed(
                                offset: controller.text.length,
                              );
                            });
                            return;
                          }

                          setState(() {
                            _counts[prayer] = parsed ?? 0;
                          });
                        },
                        onSubmitted: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed == null) {
                            setState(() {
                              _counts[prayer] = 0;
                              controller.text = '0';
                              controller.selection =
                                  const TextSelection.collapsed(offset: 1);
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        if (count >= _maxCount) {
                          _showLimitAlert();
                          return;
                        }

                        setState(() {
                          final next = count + 1;
                          _counts[prayer] = next;
                          controller.text = next.toString();
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
