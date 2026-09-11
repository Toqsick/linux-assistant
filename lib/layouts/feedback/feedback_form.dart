import 'package:flutter/material.dart';
import 'package:linux_assistant/layouts/feedback/feedback_send.dart';
import 'package:linux_assistant/layouts/mint_y.dart';
import 'package:linux_assistant/models/action_entry.dart';
import 'package:linux_assistant/services/feedback_service.dart';
import 'package:linux_assistant/l10n/app_localizations.dart';

class FeedbackDialog extends StatefulWidget {
  final String searchText;
  final List<ActionEntry> foundEntries;

  final bool calledFromHome;

  const FeedbackDialog(
      {super.key,
      required this.calledFromHome,
      this.searchText = "",
      this.foundEntries = const []});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final messageController = TextEditingController();

  // Checkbox state belongs to the state object. It used to be written back
  // into the widget, which Flutter is free to replace on any rebuild.
  bool _includeSearchTermAndResults = true;
  bool _includeBasicSystemInformation = true;

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.sendFeedback,
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              maxLines: 10,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: AppLocalizations.of(context)!.feedbackPlaceholder),
              style: Theme.of(context).textTheme.bodyLarge,
              controller: messageController,
            ),
            if (!widget.calledFromHome)
              Row(
                children: [
                  Checkbox(
                      activeColor: MintY.currentColor,
                      value: _includeSearchTermAndResults,
                      onChanged: ((value) => setState(() {
                            _includeSearchTermAndResults = value!;
                          }))),
                  Text(
                    AppLocalizations.of(context)!.includeSearchTermAndResults,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            Row(
              children: [
                Checkbox(
                    activeColor: MintY.currentColor,
                    value: _includeBasicSystemInformation,
                    onChanged: ((value) => setState(() {
                          _includeBasicSystemInformation = value!;
                        }))),
                Text(
                  AppLocalizations.of(context)!.includeBasicSystemInformation,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(
              height: 32,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MintYButton(
                  text: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: MintY.heading4,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(
                  width: 10,
                ),
                MintYButton(
                  color: MintY.currentColor,
                  text: Text(
                    AppLocalizations.of(context)!.submit,
                    style: MintY.heading4White,
                  ),
                  onPressed: () {
                    Future<bool> success = FeedbackService.sendFeedback(
                        messageController.text,
                        widget.foundEntries,
                        widget.searchText,
                        _includeBasicSystemInformation,
                        widget.calledFromHome
                            ? false
                            : _includeSearchTermAndResults);
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (context) => FeedbackSent(
                        success: success,
                      ),
                    );
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
