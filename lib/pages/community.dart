import 'package:flutter/material.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  bool showFriendsDropdown = false;
  bool showGroupsDropdown = false;

  final List<String> friends = ['Friend 1', 'Friend 2', 'Friend 3'];
  final List<String> groups = ['Group 1', 'Group 2'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('COMMUNITY', style: TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.email, color: Colors.white),
            onPressed: () {
              // Handle email button press
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[850],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildSectionWithButtonAndDropdown(
              icon: Icons.person_outline,
              title: 'FREUNDESLISTE',
              buttonText: 'ADD FRIEND',
              showDropdown: showFriendsDropdown,
              onButtonPressed: () {
                // Handle Add Friend button press
              },
              onDropdownToggle: () {
                setState(() {
                  showFriendsDropdown = !showFriendsDropdown;
                });
              },
              titleFontSize: 16.0,
              dropdownContent: buildFriendsDropdownContent(),
            ),
            const SizedBox(height: 16.0),

            buildSectionWithButtonAndDropdown(
              icon: Icons.group_outlined,
              title: 'GRUPPEN',
              buttonText: 'CREATE GROUP',
              showDropdown: showGroupsDropdown,
              onButtonPressed: () {
                // Handle Create Group button press
              },
              onDropdownToggle: () {
                setState(() {
                  showGroupsDropdown = !showGroupsDropdown;
                });
              },
              titleFontSize: 16.0,
              dropdownContent: buildGroupsDropdownContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionWithButtonAndDropdown({
    required IconData icon,
    required String title,
    required String buttonText,
    required bool showDropdown,
    required VoidCallback onButtonPressed,
    required VoidCallback onDropdownToggle,
    required double titleFontSize,
    required Widget dropdownContent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8.0),
              Expanded(
                flex: 4,
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  showDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.white,
                ),
                onPressed: onDropdownToggle,
              ),
              const SizedBox(width: 8.0),
              Flexible(
                flex: 3,
                child: TextButton.icon(
                  onPressed: onButtonPressed,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18.0),
                  label: Text(buttonText, style: const TextStyle(color: Colors.white, fontSize: 14.0)),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white, thickness: 1),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: showDropdown ? dropdownContent : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget buildFriendsDropdownContent() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: friends.map((friend) {
          return ListTile(
            title: Text(friend, style: const TextStyle(color: Colors.white)),
            onTap: () {
              // Handle friend item tap
            },
          );
        }).toList(),
      ),
    );
  }

  Widget buildGroupsDropdownContent() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: groups.map((group) {
          return ListTile(
            title: Text(group, style: const TextStyle(color: Colors.white)),
            onTap: () {
              // Handle group item tap
            },
          );
        }).toList(),
      ),
    );
  }
}
