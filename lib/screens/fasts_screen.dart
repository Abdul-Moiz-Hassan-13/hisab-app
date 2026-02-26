import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FastsScreen extends StatefulWidget {
  const FastsScreen({super.key, required this.initialCount});

  final int initialCount;

  @override
  State<FastsScreen> createState() => _FastsScreenState();
}

class _FastsScreenState extends State<FastsScreen> {
  late int _count;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount;
    _controller = TextEditingController(text: _count.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        Navigator.pop(context, _count);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Missed Fasts'),
          centerTitle: true,
          leading: BackButton(onPressed: () => Navigator.pop(context, _count)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: ListTile(
              title: const Text('Compulsory Fasts'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _count == 0
                        ? null
                        : () {
                            setState(() {
                              final next = _count - 1;
                              _count = next;
                              _controller.text = next.toString();
                            });
                          },
                  ),
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _controller,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        setState(() {
                          _count = parsed ?? 0;
                        });
                      },
                      onSubmitted: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed == null) {
                          setState(() {
                            _count = 0;
                            _controller.text = '0';
                            _controller.selection =
                                const TextSelection.collapsed(offset: 1);
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      setState(() {
                        final next = _count + 1;
                        _count = next;
                        _controller.text = next.toString();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
