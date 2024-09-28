import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InboxPage extends StatelessWidget {
  // Fetching group invites dynamically using StreamBuilder
  Stream<List<Map<String, dynamic>>> getGroupInvites() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('group_invites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to the Community page
          },
        ),
        title: const Text('Inbox', style: TextStyle(color: Colors.white, fontSize: 22)),
      ),
      body: Container(
        color: Colors.grey[850],
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Fetch and display friend invites
            _buildFriendInviteSection(),
            const SizedBox(height: 16.0),
            // Fetch and display group invites
            _buildGroupInviteSection(),
          ],
        ),
      ),
    );
  }

  // Widget to fetch and build friend invites
  Widget _buildFriendInviteSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getFriendRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No friend requests.", style: TextStyle(color: Colors.white)));
        }

        final friendRequests = snapshot.data!;

        return _buildInviteSection('Friend Invites', friendRequests, true);
      },
    );
  }

  // Widget to fetch and build group invites
  Widget _buildGroupInviteSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getGroupInvites(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No group invites.", style: TextStyle(color: Colors.white)));
        }

        final groupInvites = snapshot.data!;

        return _buildInviteSection('Group Invites', groupInvites, false);
      },
    );
  }

  // Build invite section for friend and group invites
  Widget _buildInviteSection(String title, List<Map<String, dynamic>> invites, bool isFriendInvite) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white, thickness: 1),
          Column(
            children: invites.map((invite) {
              return ListTile(
                title: Text(invite[isFriendInvite ? 'fromUserName' : 'groupName'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        if (isFriendInvite) {
                          await acceptFriendRequest(invite['fromUserId'], invite['fromUserName'], invite['fromUserEmail']);
                        } else {
                          await acceptGroupInvite(invite['groupId'], invite['groupName']);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        if (isFriendInvite) {
                          await declineFriendRequest(invite['fromUserId']);
                        } else {
                          await declineGroupInvite(invite['groupId']);
                        }
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Fetch friend requests dynamically
  Stream<List<Map<String, dynamic>>> getFriendRequests() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('friend_requests')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Accept Group Invite
  Future<void> acceptGroupInvite(String groupId, String groupName) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    // Step 1: Add the user to the group's 'members' array
    await firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([currentUser!.uid]),
    });

    // Step 2: Remove the invite from the user's 'group_invites' sub-collection
    final inviteQuery = await firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('group_invites')
        .where('groupId', isEqualTo: groupId)
        .get();

    if (inviteQuery.docs.isNotEmpty) {
      await inviteQuery.docs.first.reference.delete();
    }

    print("Group invite for $groupName accepted.");
  }

  // Decline Group Invite
  Future<void> declineGroupInvite(String groupId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    // Find and delete the group invite
    final inviteQuery = await firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('group_invites')
        .where('groupId', isEqualTo: groupId)
        .get();

    if (inviteQuery.docs.isNotEmpty) {
      await inviteQuery.docs.first.reference.delete();
    }

    print("Group invite declined.");
  }

  // Accept Friend Request Function
  Future<void> acceptFriendRequest(String fromUserId, String fromUserName, String fromUserEmail) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    // Step 1: Add the friend to the current user's 'friends' sub-collection
    await firestore.collection('users').doc(currentUser!.uid).collection('friends').add({
      'friendId': fromUserId,
      'friendName': fromUserName,
      'friendEmail': fromUserEmail,
    });

    // Step 2: Add the current user to the friend's 'friends' sub-collection
    await firestore.collection('users').doc(fromUserId).collection('friends').add({
      'friendId': currentUser.uid,
      'friendName': currentUser.displayName ?? 'Anonymous',
      'friendEmail': currentUser.email,
    });

    // Step 3: Remove the friend request after it is accepted
    final requestQuery = await firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: fromUserId)
        .get();

    if (requestQuery.docs.isNotEmpty) {
      await requestQuery.docs.first.reference.delete();
    }

    print("Friend request accepted.");
  }

  // Decline Friend Request Function
  Future<void> declineFriendRequest(String fromUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    // Find and delete the friend request
    final requestQuery = await firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: fromUserId)
        .get();

    if (requestQuery.docs.isNotEmpty) {
      await requestQuery.docs.first.reference.delete();
    }

    print("Friend request declined.");
  }
}

