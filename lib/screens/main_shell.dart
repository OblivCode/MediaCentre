import 'package:flutter/material.dart';

import 'library_domain.dart';
import 'library_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  LibraryDomain _domain = LibraryDomain.watch;
  LibrarySort _sort = LibrarySort.recentlyAdded;

  void _setDomain(LibraryDomain domain) {
    if (_domain == domain) return;
    setState(() {
      _domain = domain;
    });
  }

  int _domainIndex(LibraryDomain domain) =>
      LibraryDomain.values.indexOf(domain);

  Widget _buildContent() {
    return LibraryScreen(
      domain: _domain,
      sort: _sort,
      onSortChanged: (sort) => setState(() => _sort = sort),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.movie), label: 'Watch'),
      const NavigationDestination(icon: Icon(Icons.menu_book), label: 'Read'),
      const NavigationDestination(
          icon: Icon(Icons.music_note), label: 'Listen'),
      const NavigationDestination(
          icon: Icon(Icons.folder), label: 'Collections'),
    ];

    if (isMobile) {
      return Scaffold(
        body: _buildContent(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _domainIndex(_domain),
          onDestinationSelected: (index) =>
              _setDomain(LibraryDomain.values[index]),
          destinations: destinations,
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _domainIndex(_domain),
            onDestinationSelected: (index) =>
                _setDomain(LibraryDomain.values[index]),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.movie),
                label: Text('Watch'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.menu_book),
                label: Text('Read'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.music_note),
                label: Text('Listen'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder),
                label: Text('Collections'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}
