import 'package:flutter/material.dart';
import 'communitypage/inbox.dart'; // Import the inbox page

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
        title: const Text('COMMUNITY', style: TextStyle(color: Colors.white, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox, color: Colors.white),
            onPressed: () {
              // Navigate to InboxPage when the inbox icon is clicked
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InboxPage()), // Push to new InboxPage
              );
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
                _showFriendSearchPopup(context);
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
                _showCreateCommunityPopup(context);
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

  // Pop-up for searching friends
  void _showFriendSearchPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Friends'),
          content: TextField(
            decoration: const InputDecoration(hintText: 'Enter email or username'),
            onChanged: (value) {
              // Handle search logic here
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                // Handle friend adding logic here
              },
              child: const Text('ADD'),
            ),
          ],
        );
      },
    );
  }

  // Pop-up for creating a community with "Allow Invites" option for private groups
  void _showCreateCommunityPopup(BuildContext context) {
    bool isPrivate = false;
    bool allowInvites = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Community'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(hintText: 'Community Name'),
                    onChanged: (value) {
                      // Handle community name input
                    },
                  ),
                  Row(
                    children: [
                      const Text('Private'),
                      Switch(
                        value: isPrivate,
                        onChanged: (value) {
                          setState(() {
                            isPrivate = value;
                            if (!isPrivate) {
                              allowInvites = false; // Reset allow invites if the group is public
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (isPrivate)
                    Row(
                      children: [
                        const Text('Allow Invites'),
                        Switch(
                          value: allowInvites,
                          onChanged: (value) {
                            setState(() {
                              allowInvites = value;
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    // Handle community creation logic here
                    Navigator.pop(context);
                  },
                  child: const Text('CREATE'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}









