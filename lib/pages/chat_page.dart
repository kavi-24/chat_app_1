import 'package:chat_app_1/pages/group_info.dart';
import 'package:chat_app_1/service/database_service.dart';
import 'package:chat_app_1/widgets/message_tile.dart';
import 'package:chat_app_1/widgets/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String userName;
  const ChatPage(
      {super.key,
      required this.groupId,
      required this.groupName,
      required this.userName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Stream<QuerySnapshot>? chats;
  String admin = "";

  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    getChatAdmin();
    super.initState();
  }

  getChatAdmin() {
    DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid).getChats(widget.groupId).then((value) {
      setState(() {
        chats = value;
      });
    });
    DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid).getGroupAdmin(widget.groupId).then((value) {
      setState(() {
        admin = value.toString().split("_")[1];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text(
          widget.groupName,
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            onPressed: () {
              nextScreen(context, GroupInfo(
                adminName: admin,
                groupId: widget.groupId,
                groupName: widget.groupName,
              ));
            },
            icon: Icon(Icons.info)
          )
        ],
      ),
      body: Stack (
        children: [
          chatMessages(),
          Container(
            alignment: Alignment.bottomCenter,
            width: MediaQuery.of(context).size.width,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), ),
                color: Colors.grey,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              width: MediaQuery.of(context).size.width,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: messageController,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Send a message...",
                        hintStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 16
                        ),
                        border: InputBorder.none
                      ),
                    ),
                  ),
                  const SizedBox(width: 12,),
                  GestureDetector(
                    onTap: () {
                      sendMessage();
                    },
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(Icons.send, color: Colors.white,),
                    ),
                  )
                ],
              )
            )
          )
        ],
      ),
    );
  }
  
  chatMessages() {
    return StreamBuilder(
      stream: chats,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData ? ListView.builder(
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            return MessageTile(message: snapshot.data.docs[index]['message'], sender: snapshot.data.docs[index]['sender'], sentByMe: widget.userName == snapshot.data.docs[index]['sender']);
          }
        ) : Container();
      }
    );
  }

  sendMessage() {
    if (messageController.text.isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        "message": messageController.text,
        "sender": widget.userName,
        "time": DateTime.now().millisecondsSinceEpoch
      };
      DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid).sendMessage(
        widget.groupId, chatMessageMap
      );
      setState(() {
        messageController.text = "";
      });
    }
  }

}
