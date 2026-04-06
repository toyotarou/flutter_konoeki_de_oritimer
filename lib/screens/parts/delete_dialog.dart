import 'package:flutter/material.dart';

Future<void> showDeleteDialog({
  required BuildContext context,
  required VoidCallback onConfirm,
  String content = 'このデータを消去しますか？',
}) async {
  final Widget cancelButton = TextButton(onPressed: () => Navigator.pop(context), child: const Text('いいえ'));

  final Widget continueButton = TextButton(
    onPressed: () {
      Navigator.pop(context);
      onConfirm();
    },
    child: const Text('はい'),
  );

  final AlertDialog alert = AlertDialog(
    backgroundColor: Colors.blueGrey.withValues(alpha: 0.3),
    content: Text(content),
    actions: <Widget>[cancelButton, continueButton],
  );

  // ignore: inference_failure_on_function_invocation
  await showDialog(context: context, builder: (BuildContext context) => alert);
}
