import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/reminders_provider.dart';
import 'agenda_page.dart';
import 'chat_page.dart';
import 'dashboard_page.dart';
import 'notes_page.dart';
import 'reminders_page.dart';

/// Coque principale : barre de navigation en bas + 5 onglets.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  /// Permet à n'importe quel écran de changer d'onglet :
  /// `HomeShell.goTo(context, 1)` ouvre le chat.
  static void goTo(BuildContext context, int index) {
    context.findAncestorStateOfType<_HomeShellState>()?._select(index);
  }

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );

  static const _pages = <Widget>[
    DashboardPage(),
    ChatPage(),
    NotesPage(),
    RemindersPage(),
    AgendaPage(),
  ];

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _index = i);
    _fade.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = context.watch<RemindersProvider>().upcoming.length;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        body: FadeTransition(
          opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
          child: IndexedStack(index: _index, children: _pages),
        ),
        // On cache la barre quand le clavier est ouvert (chat, notes…).
        bottomNavigationBar: keyboardOpen
            ? null
            : NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _select,
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Accueil',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline),
                    selectedIcon: Icon(Icons.chat_bubble),
                    label: 'Chat',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.sticky_note_2_outlined),
                    selectedIcon: Icon(Icons.sticky_note_2),
                    label: 'Notes',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: upcoming > 0,
                      label: Text('$upcoming'),
                      child: const Icon(Icons.alarm_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: upcoming > 0,
                      label: Text('$upcoming'),
                      child: const Icon(Icons.alarm),
                    ),
                    label: 'Rappels',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month),
                    label: 'Agenda',
                  ),
                ],
              ),
      ),
    );
  }
}
