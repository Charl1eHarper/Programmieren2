import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'communitypage/inbox.dart'; // Import the inbox page
import 'communitypage/friendPopUp.dart'; // Import the friend popup page

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  bool showFriendsDropdown = false;
  bool showGroupsDropdown = false;

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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InboxPage()), // Push to InboxPage
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

  // Fetch friends from Firestore and display them
  Widget buildFriendsDropdownContent() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('users').doc(currentUser!.uid).collection('friends').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'No friends added yet.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final friendsDocs = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: friendsDocs.length,
          itemBuilder: (context, index) {
            var friend = friendsDocs[index];
            return ListTile(
              title: Text(friend['friendName'], style: const TextStyle(color: Colors.white)),
              onTap: () {
                // Open the FriendProfilePopup when a friend is tapped
                showDialog(
                  context: context,
                  builder: (context) => FriendProfilePopup(friendId: friend.id),
                );
              },
            );
          },
        );
      },
    );
  }

  // Fetch groups from Firestore and display them
  Widget buildGroupsDropdownContent() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('groups').where('members', arrayContains: currentUser!.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'No groups found.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final groupsDocs = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: groupsDocs.length,
          itemBuilder: (context, index) {
            var group = groupsDocs[index];
            return ListTile(
              title: Text(group['groupName'], style: const TextStyle(color: Colors.white)),
              subtitle: group['isPrivate']
                  ? const Text('Private Group', style: TextStyle(color: Colors.grey))
                  : const Text('Public Group', style: TextStyle(color: Colors.grey)),
              trailing: IconButton(
                icon: Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  // Open group options when the settings icon is clicked
                  _showGroupOptionsPopup(context, group);
                },
              ),
              onTap: () {
                print('Tapped on ${group['groupName']}');
              },
            );
          },
        );
      },
    );
  }

  // Group options popup (Settings: make public/private, delete, allow invites, invite users)
  void _showGroupOptionsPopup(BuildContext context, DocumentSnapshot group) {
    bool isPrivate = group['isPrivate'];
    bool allowInvites = group['allowInvites'];
    TextEditingController inviteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Manage ${group['groupName']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Private'),
                      Switch(
                        value: isPrivate,
                        onChanged: (value) async {
                          setState(() {
                            isPrivate = value;
                          });
                          await _updateGroupPrivacy(group.id, value);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Allow Invites'),
                      Switch(
                        value: allowInvites,
                        onChanged: (value) async {
                          setState(() {
                            allowInvites = value;
                          });
                          await _updateGroupInvites(group.id, value);
                        },
                      ),
                    ],
                  ),
                  TextField(
                    controller: inviteController,
                    decoration: InputDecoration(hintText: 'Invite user by email'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (inviteController.text.isNotEmpty) {
                        await _inviteUserToGroup(inviteController.text, group.id, group['groupName']);
                      }
                    },
                    child: const Text('INVITE'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _deleteGroup(group.id);
                    Navigator.pop(context);
                  },
                  child: const Text('DELETE GROUP', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('CLOSE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Firestore: Update group privacy
  Future<void> _updateGroupPrivacy(String groupId, bool isPrivate) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('groups').doc(groupId).update({'isPrivate': isPrivate});
    print('Group privacy updated.');
  }

  // Firestore: Update group invite permission
  Future<void> _updateGroupInvites(String groupId, bool allowInvites) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('groups').doc(groupId).update({'allowInvites': allowInvites});
    print('Group invites permission updated.');
  }

  // Firestore: Invite a user to the group (Send invite instead of adding directly)
  Future<void> _inviteUserToGroup(String email, String groupId, String groupName) async {
    final firestore = FirebaseFirestore.instance;
    final userQuery = await firestore.collection('users').where('email', isEqualTo: email).get();

    if (userQuery.docs.isNotEmpty) {
      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;

      // Add an invite to the user's group_invites sub-collection
      await firestore.collection('users').doc(userId).collection('group_invites').add({
        'groupId': groupId,
        'groupName': groupName,
        'invitedBy': FirebaseAuth.instance.currentUser!.uid, // The user sending the invite
        'createdAt': Timestamp.now(),
      });

      print('User invited to group.');
    } else {
      print('User not found.');
    }
  }

  // Firestore: Delete group
  Future<void> _deleteGroup(String groupId) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('groups').doc(groupId).delete();
    print('Group deleted.');
  }

  // Pop-up for searching friends
  void _showFriendSearchPopup(BuildContext context) {
    TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Friends'),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(hintText: 'Enter email or username'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                await sendFriendRequest(searchController.text);
                Navigator.pop(context);
              },
              child: const Text('ADD'),
            ),
          ],
        );
      },
    );
  }

  // Send Friend Request Function
  Future<void> sendFriendRequest(String friendEmail) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    final friendQuery = await firestore.collection('users').where('email', isEqualTo: friendEmail).get();

    if (friendQuery.docs.isNotEmpty) {
      final friendDoc = friendQuery.docs.first;
      final friendId = friendDoc.id;

      await firestore.collection('users').doc(friendId).collection('friend_requests').add({
        'fromUserId': currentUser!.uid,
        'fromUserName': currentUser.displayName ?? 'Anonymous',
        'fromUserEmail': currentUser.email,
        'createdAt': Timestamp.now(),
      });

      print("Friend request sent.");
    } else {
      print('Friend not found.');
    }
  }

  // Pop-up for creating a community with "Allow Invites" option for private groups
  void _showCreateCommunityPopup(BuildContext context) {
    bool isPrivate = false;
    bool allowInvites = false;
    TextEditingController groupNameController = TextEditingController();

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
                    controller: groupNameController,
                    decoration: const InputDecoration(hintText: 'Community Name'),
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
                              allowInvites = false;
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
                  onPressed: () async {
                    String groupName = groupNameController.text.trim();
                    if (groupName.isNotEmpty) {
                      await _createCommunity(groupName, isPrivate, allowInvites);
                      Navigator.pop(context);
                    } else {
                      print('Group name cannot be empty');
                    }
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

  // Function to create a community (group) in Firestore
  Future<void> _createCommunity(String groupName, bool isPrivate, bool allowInvites) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('groups').add({
      'groupName': groupName,
      'isPrivate': isPrivate,
      'allowInvites': allowInvites,
      'createdBy': currentUser!.uid,
      'createdAt': Timestamp.now(),
      'members': [currentUser.uid],
    });

    print('Group "$groupName" created successfully');
  }
}















