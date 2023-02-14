import 'package:flutter/material.dart';
import 'style.dart' as style;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'notification.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (c) => Store()),
        ChangeNotifierProvider(create: (c) => subStore()),
      ],

      child: MaterialApp(
        theme: style.theme,
        home: const MyApp(),
      ),
    )
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var tab = 0;
  var serverData = [];
  var userImage;

  saveData() async {
    var storage = await SharedPreferences.getInstance();

  }

  getData() async {
    var res = await http.get(Uri.parse('https://codingapple1.github.io/app/data.json'));

    if(res.statusCode == 200) {
      var decodedRes = jsonDecode(res.body);

      setState(() {
        serverData = decodedRes;
      });
    } else {
      //
    }
  }

  addPost(dataObj) {
    setState(() {
      serverData.insert(0, dataObj);
    });
  }
  
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initNotification(context);
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(child: Text('+'), onPressed: () {
        showNotification();
      },),
      appBar: AppBar(title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Instagram'),
          IconButton(
            icon: Icon(Icons.add_box_outlined,),
            iconSize: 30,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onPressed: () async {
              var picker = ImagePicker();
              var image = await picker.pickImage(source: ImageSource.gallery);

              if(image != null) {
                setState(() {
                  userImage = File(image.path);
                });
              }

              Navigator.push(context,
                MaterialPageRoute(builder: (c){
                  return Upload(userImage: userImage, addPost: addPost);
                })
              );
            },
          )
        ],)
      ),
      // pageView
      body: PageView(
        children: [
          [PostBox(data : serverData), Text('샵')][tab]
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        // 라벨에 정보 뜨는거 제거
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (i) {
          setState(() {
            tab = i;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined), label: '샵'),
        ],
      ),
    );
  }
}

class PostBox extends StatefulWidget {
  const PostBox({Key? key, this.data}) : super(key: key);
  final data;

  @override
  State<PostBox> createState() => _PostBoxState();
}

class _PostBoxState extends State<PostBox> {
  var scroll = ScrollController();

  getMore() async {
    var res = await http.get(Uri.parse('https://codingapple1.github.io/app/more1.json'));

    if(res.statusCode == 200) {
      var decodedRes = jsonDecode(res.body);

      setState(() {
        widget.data.add(decodedRes);
      });
    } else {
      //
    }
  }

  @override
  void initState() {
    super.initState();
    scroll.addListener(() {
      if (scroll.position.pixels == scroll.position.maxScrollExtent) {
        getMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if(widget.data.isNotEmpty) {
      return ListView.builder(
        controller: scroll,
        itemBuilder: (c, i) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.data[i]['image'].runtimeType == String ? Image.network(widget.data[i]['image']) : Image.file(widget.data[i]['image']),
              Text('좋아요 ${widget.data[i]['likes']}', style: TextStyle(fontWeight: FontWeight.bold)),
              GestureDetector(
                child: Text(widget.data[i]['user']),
                onTap: (){
                  context.read<Store>().getUserImage();
                  Navigator.push(context, CupertinoPageRoute(builder: (c) => Profile()));
                },
              ),
              Text(widget.data[i]['content']),
            ],
          );
        },
        itemCount: widget.data.length,
      );
    } else {
      return Text('Loading');
    }
  }
}

class Upload extends StatelessWidget {
  Upload({Key? key, this.userImage, this.addPost}) : super(key: key);
  final userImage;
  final addPost;
  final _contentEditController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actions: [
          IconButton(onPressed: () {
            addPost({
              "image":userImage,
              "likes":"0",
              "data":"",
              "content":_contentEditController.text,
              "user":"seokbong",
            });
            Navigator.pop(context);
          },
            icon: Icon(Icons.add),
          )
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.file(userImage),
            Text('image upload'),
            TextField(
              controller: _contentEditController,
              decoration: InputDecoration(
                labelText: 'content',
              ),
            ),
            // IconButton(onPressed: () {
            //   Navigator.pop(context);
            // }, icon: Icon(Icons.close))
          ],
        ),
      )
    );
  }
}

class Store extends ChangeNotifier {
  String name = 'seokbong';
  int follow = 0;
  bool isFollowed = false;
  var userImage = [];

  chkFollow() {
    if(isFollowed == false){
      follow++;
      isFollowed = true;
    } else {
      follow--;
      isFollowed = false;
    }
    notifyListeners();  // re-rendering 해주세요.
  }

  getUserImage() async {
    var res = await http.get(Uri.parse('https://codingapple1.github.io/app/profile.json'));
    if(res.statusCode == 200) {
      var resJson = jsonDecode(res.body);
      userImage = resJson;
      print(userImage);
      notifyListeners();
    } else {
      //
    }
  }
}

class subStore extends ChangeNotifier {

}

class Profile extends StatelessWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
      return Scaffold(
          appBar: AppBar(title: Text(context.watch<Store>().name),),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ProfileHeader(),
              ),
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                      (c, i) => Container(
                        // color: Colors.grey,
                        child: Image.network(context.watch<Store>().userImage[i]),
                  ),
                  childCount: context.watch<Store>().userImage.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
              )
          ],
          )
      );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Spacer(),
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey,
        ),
        Spacer(flex:2),
        Text('팔로워 ${context.read<Store>().follow} 명'),
        Spacer(flex:2),
        ElevatedButton(
          onPressed: (){ context.read<Store>().chkFollow(); },
          child: Text(context.read<Store>().isFollowed?'Following':'Follow'),
        ),
        Spacer(),
      ],
    );
  }
}
