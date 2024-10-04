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
  String searchQuery = ""; // Search query for public groups
  List<DocumentSnapshot> searchResults = []; // Search results for public groups
  bool isSearching = false; // To track if search is ongoing in the background
  final currentUser = FirebaseAuth.instance.currentUser; // Current logged-in user

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('COMMUNITY', style: TextStyle(color: Colors.black, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox, color: Colors.black),
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
        color: Colors.grey[300], // Light background color
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildSearchBar(), // Search bar for finding public groups
            const SizedBox(height: 16.0),
            // Dynamically sized search results below the search bar
            if (searchResults.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    var group = searchResults[index];
                    List<dynamic> members = group['members'];

                    // Check if the current user is already a member of the group
                    bool isMember = members.contains(currentUser!.uid);

                    return ListTile(
                      title: Text(group['groupName'], style: const TextStyle(color: Colors.black)),
                      subtitle: const Text('Public Group', style: TextStyle(color: Colors.black54)),
                      trailing: isMember
                          ? const Text('Member', style: TextStyle(color: Colors.green)) // Show "Member" if already part of the group
                          : TextButton(
                        onPressed: () {
                          _joinGroup(group.id);
                        },
                        child: const Text('Join', style: TextStyle(color: Colors.teal)), // Show "Join" button otherwise
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16.0),
            // The friend list and group sections are always displayed after search results
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

  // Build the search bar for public groups
  Widget buildSearchBar() {
    return TextField(
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: 'Search for public groups...',
        hintStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.search, color: Colors.black),
      ),
      onChanged: (value) {
        setState(() {
          searchQuery = value.trim();
        });
        if (searchQuery.isNotEmpty) {
          _searchForPublicGroups(); // Perform search when there's input
        } else {
          setState(() {
            searchResults = [];
          });
        }
      },
    );
  }

  // Fetch public groups from Firestore that match the search query
  Future<void> _searchForPublicGroups() async {
    setState(() {
      isSearching = true; // Mark as searching in the background
    });

    final firestore = FirebaseFirestore.instance;

    QuerySnapshot querySnapshot = await firestore
        .collection('groups')
        .where('isPrivate', isEqualTo: false)
        .where('groupName', isGreaterThanOrEqualTo: searchQuery)
        .where('groupName', isLessThanOrEqualTo: '$searchQuery\uf8ff')
        .get();

    setState(() {
      searchResults = querySnapshot.docs;
      isSearching = false; // Stop searching in the background
    });
  }

  // Function to join a public group
  Future<void> _joinGroup(String groupId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Update the group to add the current user as a member
      await firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([currentUser!.uid]),
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined the group!')),
      );

      // Refresh search results to update the UI
      _searchForPublicGroups();
    } catch (e) {
      // Handle error (if any)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join the group: $e')),
      );
    }
  }

  // Build sections for friends and groups
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 8.0),
              Expanded(
                flex: 4,
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  showDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.black,
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
                  icon: const Icon(Icons.add, color: Colors.black, size: 18.0),
                  label: Text(buttonText, style: const TextStyle(color: Colors.black, fontSize: 14.0)),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.black, thickness: 1),
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
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('users').doc(currentUser!.uid).collection('friends').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'No friends added yet.',
              style: TextStyle(color: Colors.black),
            ),
          );
        }

        final friendsDocs = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: friendsDocs.length,
          itemBuilder: (context, index) {
            var friend = friendsDocs[index];
            return ListTile(
              title: Text(friend['friendName'] != 'Anonymous' ? friend['friendName'] : friend['friendEmail'],
                  style: const TextStyle(color: Colors.black)),
              onTap: () {
                // Open the FriendProfilePopup when a friend is tapped
                showDialog(
                  context: context,
                  builder: (context) => FriendProfilePopup(friendId: friend['friendId']),
                );
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _showUnfriendConfirmation(friend['friendId']);
                },
              ),
            );
          },
        );
      },
    );
  }

// Function to show the unfriend confirmation dialog
  void _showUnfriendConfirmation(String friendId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unfriend', style: TextStyle(color: Colors.black)),
          content: const Text('Are you sure you want to unfriend this person?', style: TextStyle(color: Colors.black)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Unfriend', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _unfriendUser(friendId); // Call unfriend function
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


// Function to remove a friend from Firestore
  Future<void> _unfriendUser(String friendId) async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    try {
      // Query the 'friends' collection to find the document with the matching friendId
      QuerySnapshot snapshot = await firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('friends')
          .where('friendId', isEqualTo: friendId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // If a matching document is found, delete it
        await snapshot.docs.first.reference.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend removed successfully')),
        );

        // Confirm successful deletion in the console
      } else {
        // No document found with the matching friendId
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No friend found with this ID')),
        );
      }
    } catch (e) {
      // Log any errors encountered during deletion

      // Show error message if deletion fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove friend: $e')),
      );
    }
  }

  // Fetch groups from Firestore and display them
  Widget buildGroupsDropdownContent() {
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('groups').where('members', arrayContains: currentUser!.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'No groups found.',
              style: TextStyle(color: Colors.black),
            ),
          );
        }

        final groupsDocs = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: groupsDocs.length,
          itemBuilder: (context, index) {
            var group = groupsDocs[index];
            return ListTile(
              title: Text(group['groupName'], style: const TextStyle(color: Colors.black)),
              subtitle: group['isPrivate']
                  ? const Text('Private Group', style: TextStyle(color: Colors.black))
                  : const Text('Public Group', style: TextStyle(color: Colors.black)),
              trailing: IconButton(
                icon: const Icon(Icons.settings, color: Colors.black),
                onPressed: () {
                  // Open group options when the settings icon is clicked
                  _showGroupOptionsPopup(context, group);
                },
              ),
              onTap: () {
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
                    decoration: const InputDecoration(hintText: 'Invite user by email'),
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
                  child: const Text('CLOSE', style: TextStyle(color: Colors.black),),
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
  }

  // Firestore: Update group invite permission
  Future<void> _updateGroupInvites(String groupId, bool allowInvites) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('groups').doc(groupId).update({'allowInvites': allowInvites});
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

    } else {
    }
  }

  // Firestore: Delete group
  Future<void> _deleteGroup(String groupId) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('groups').doc(groupId).delete();
  }

  // Pop-up for searching friends
  void _showFriendSearchPopup(BuildContext context) {
    TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[300], // Set the background color to match the page
          title: const Text(
            'Search Friends',
            style: TextStyle(color: Colors.black), // White text to fit the theme
          ),
          content: TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.black), // White text inside input
            decoration: const InputDecoration(
              hintText: 'Enter email',
              hintStyle: TextStyle(color: Colors.black), // Subtle hint color
              filled: true,
              fillColor: Colors.white, // Dark background for input field
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () async {
                await sendFriendRequest(searchController.text);
                Navigator.pop(context);
              },
              child: const Text('ADD', style: TextStyle(color: Colors.blue)),
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

    } else {
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
              backgroundColor: Colors.grey[300], // Set the background color to match the page
              title: const Text(
                'Create Community',
                style: TextStyle(color: Colors.black), // White text to fit the theme
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: groupNameController,
                    style: const TextStyle(color: Colors.black), // White text inside input
                    decoration: const InputDecoration(
                      hintText: 'Community Name',
                      hintStyle: TextStyle(color: Colors.black), // Subtle hint color
                      filled: true,
                      fillColor: Colors.white, // Dark background for input field
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Text('Private', style: TextStyle(color: Colors.black)),
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
                        const Text('Allow Invites', style: TextStyle(color: Colors.black)),
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
                  child: const Text('CANCEL', style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: () async {
                    String groupName = groupNameController.text.trim();
                    if (groupName.isNotEmpty) {
                      await _createCommunity(groupName, isPrivate, allowInvites);
                      Navigator.pop(context);
                    } else {
                    }
                  },
                  child: const Text('CREATE', style: TextStyle(color: Colors.blue)),
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

  }
}

























