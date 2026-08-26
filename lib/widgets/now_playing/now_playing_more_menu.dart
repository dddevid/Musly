import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../l10n/app_localizations.dart';

class NowPlayingMoreMenu extends StatelessWidget {
  const NowPlayingMoreMenu({super.key});

  void _setSleepTimer(
      BuildContext context, int minutes, PlayerProvider provider) {
    if (minutes == 0) {
      provider.setSleepTimer(Duration.zero, endCurrentSong: false);
    } else if (minutes == -1) {
      provider.setSleepTimer(Duration.zero, endCurrentSong: true);
    } else {
      provider.setSleepTimer(Duration(minutes: minutes), endCurrentSong: false);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(bottom: 32, top: 16),
      child: Consumer<PlayerProvider>(
        builder: (context, provider, child) {
          final sleepTimerRemaining = provider.sleepTimerRemaining;
          final sleepTimerEndCurrentSong = provider.sleepTimerEndCurrentSong;

          String sleepTimerText = "Off";
          if (sleepTimerEndCurrentSong) {
            sleepTimerText = AppLocalizations.of(context)!.endOfSong;
          } else if (sleepTimerRemaining != null) {
            final minutes = sleepTimerRemaining.inMinutes;
            final seconds =
                (sleepTimerRemaining.inSeconds % 60).toString().padLeft(2, '0');
            sleepTimerText = "$minutes:$seconds";
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text(AppLocalizations.of(context)!.sleepTimer),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sleepTimerText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => SimpleDialog(
                      title: Text(AppLocalizations.of(context)!.sleepTimer),
                      children: [
                        SimpleDialogOption(
                          child: Text(AppLocalizations.of(context)!.timerOff),
                          onPressed: () => _setSleepTimer(context, 0, provider),
                        ),
                        SimpleDialogOption(
                          child: Text(AppLocalizations.of(context)!
                              .sleepTimerMinutes(5)),
                          onPressed: () => _setSleepTimer(context, 5, provider),
                        ),
                        SimpleDialogOption(
                          child: Text(AppLocalizations.of(context)!
                              .sleepTimerMinutes(10)),
                          onPressed: () =>
                              _setSleepTimer(context, 10, provider),
                        ),
                        SimpleDialogOption(
                          child: Text(AppLocalizations.of(context)!
                              .sleepTimerMinutes(15)),
                          onPressed: () =>
                              _setSleepTimer(context, 15, provider),
                        ),
                        SimpleDialogOption(
                          child: Text(AppLocalizations.of(context)!
                              .sleepTimerMinutes(30)),
                          onPressed: () =>
                              _setSleepTimer(context, 30, provider),
                        ),
                        SimpleDialogOption(
                          child: Text(AppLocalizations.of(context)!.endOfSong),
                          onPressed: () =>
                              _setSleepTimer(context, -1, provider),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(indent: 56),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocalizations.of(context)!.playbackSpeed,
                            style: const TextStyle(fontSize: 16)),
                        Text(
                          "${provider.playbackSpeed.toStringAsFixed(2)}x",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: provider.playbackSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 6,
                      onChanged: (val) {
                        provider.setPlaybackSpeed(val);
                      },
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.music_note_rounded),
                title: Text(AppLocalizations.of(context)!.preservePitch),
                subtitle:
                    Text(AppLocalizations.of(context)!.preservePitchSubtitle),
                value: provider.pitchCorrection,
                onChanged: (val) {
                  provider.togglePitchCorrection();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
