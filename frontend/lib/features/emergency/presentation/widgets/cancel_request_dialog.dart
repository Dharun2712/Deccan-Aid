import 'package:flutter/material.dart';

class CancelRequestDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const CancelRequestDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Emergency Request'),
      content: const Text(
        'Are you sure you want to cancel this emergency request? '
        'This action cannot be undone, and responders will be notified to stand down.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('NO, KEEP IT'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('YES, CANCEL REQUEST'),
        ),
      ],
    );
  }
}
