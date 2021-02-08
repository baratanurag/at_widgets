import 'package:at_contact/at_contact.dart';
import 'package:at_common_flutter/at_common_flutter.dart';
import 'package:at_contacts_flutter/screens/contacts_screen.dart';
import 'package:at_contacts_group_flutter/at_contacts_group_flutter.dart';
import 'package:at_contacts_group_flutter/screens/group_view/group_view.dart';
import 'package:at_contacts_group_flutter/screens/new_group/new_group.dart';
import 'package:at_contacts_group_flutter/services/group_service.dart';
import 'package:at_contacts_group_flutter/utils/colors.dart';
import 'package:at_contacts_group_flutter/widgets/custom_toast.dart';
import 'package:at_contacts_group_flutter/widgets/error_screen.dart';
import 'package:at_contacts_group_flutter/widgets/person_horizontal_tile.dart';
import 'package:at_contacts_group_flutter/widgets/confirmation-dialog.dart';
import 'package:flutter/material.dart';

class GroupList extends StatefulWidget {
  final String currentAtsign;

  GroupList({@required this.currentAtsign});
  @override
  _GroupListState createState() => _GroupListState();
}

class _GroupListState extends State<GroupList> {
  List<AtContact> selectedContactList = List<AtContact>();
  bool showAddGroupIcon = false;

  @override
  void initState() {
    init();
    super.initState();
    GroupService().atGroupStream.listen((groupList) {
      if (groupList.length > 0) {
        showAddGroupIcon = true;
      } else {
        showAddGroupIcon = false;
      }
      setState(() {});
    });
  }

  init() async {
    await GroupService().init(widget.currentAtsign);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          showBackButton: true,
          showLeadingIcon: true,
          showTitle: true,
          titleText: 'Groups',
          showTrailingIcon: showAddGroupIcon,
          trailingIcon: Icon(
            Icons.add,
            color: AllColors().ORANGE,
          ),
          onTrailingIconPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ContactsScreen(
                    context: context,
                    asSelectionScreen: true,
                    selectedList: (selectedList) {
                      selectedContactList = selectedList;
                      if (selectedContactList.length > 0) {
                        GroupService().setSelectedContacts(selectedContactList);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewGroup(),
                          ),
                        );
                      }
                    })),
          ),
        ),
        body: StreamBuilder(
          stream: GroupService().atGroupStream,
          builder:
              (BuildContext context, AsyncSnapshot<List<AtGroup>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else {
              if (snapshot.hasError) {
                return ErrorScreen(onPressed: () {
                  GroupService().getAllGroupsDetails();
                });
              } else {
                if (snapshot.hasData) {
                  if (snapshot.data.length == 0) {
                    showAddGroupIcon = false;

                    return EmptyGroup();
                  } else {
                    return GridView.count(
                      childAspectRatio: 150 / 60, // width/height
                      primary: false,
                      padding: EdgeInsets.all(20.0),
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 20,
                      crossAxisCount: 2,
                      children: List.generate(snapshot.data.length, (index) {
                        return InkWell(
                          onLongPress: () {
                            showMyDialog(context, snapshot.data[index]);
                          },
                          onTap: () async {
                            Future.delayed(Duration(milliseconds: 50), () {
                              GroupService()
                                  .groupViewSink
                                  .add(snapshot.data[index]);
                            });

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      GroupView(group: snapshot.data[index])),
                            );
                          },
                          child: CustomPersonHorizontalTile(
                            image: (snapshot.data[index].groupPicture != null)
                                ? snapshot.data[index].groupPicture
                                : null,
                            title: snapshot.data[index].displayName ?? null,
                            subTitle:
                                '${snapshot.data[index].members.length} members',
                          ),
                        );
                      }),
                    );
                  }
                } else {
                  return EmptyGroup();
                }
              }
            }
          },
        ),
      ),
    );
  }
}

Future<void> showMyDialog(BuildContext context, AtGroup group) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return ConfirmationDialog(
        title: group.name,
        heading: 'Are you sure you want to delete this group?',
        onYesPressed: () async {
          var result = await GroupService().deleteGroup(group);

          if (result is bool) {
            result ? Navigator.of(context).pop() : null;
          } else {
            CustomToast().show(result.toString(), context);
          }
        },
      );
    },
  );
}