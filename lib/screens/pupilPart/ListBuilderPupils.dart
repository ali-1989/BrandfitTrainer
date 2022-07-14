import 'package:brandfit_trainer/system/icons.dart';
import 'package:flutter/material.dart';

import 'package:iris_tools/features/overlayDialog.dart';

import '/abstracts/stateBase.dart';
import '/database/models/userAdvancedModelDb.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/pupilPart/ListBuilderPupilsCtr.dart';
import '/system/extensions.dart';
import '/tools/app/appThemes.dart';

class ListBuilderPupils extends StatefulWidget {
  final UserAdvancedModelDb pupilModel;
  final UserModel user;
  final List<ListBuilderPupilsState> stateList;

  ListBuilderPupils(this.pupilModel, this.user, this.stateList, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ListBuilderPupilsState();
  }
}
///======================================================================================
class ListBuilderPupilsState extends StateBase<ListBuilderPupils> {
  ListBuilderPupilsCtr controller = ListBuilderPupilsCtr();

  @override
  void initState() {
    super.initState();
    controller.onInitState(this);
  }

  @override
  Widget build(BuildContext context) {
    controller.onBuild();

    return Card(
      color: Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(IconList.accountM),

                Text(controller.pupilModel.userName)
                    .boldFont(),
              ],
            ),

            SizedBox(height: 8,),

            Row(
              textDirection: AppThemes.getOppositeDirection(),
              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(AppThemes.currentTheme.infoColor)
                  ),
                  child: Text('${tInMap('pupilPage', 'pupilPrograms')}'),
                  onPressed: (){
                    controller.gotoProgramsPage(controller.pupilModel);
                  },
                ),

                SizedBox(width: 10,),
                TextButton(
                  onPressed: (){
                    OverlayDialog().hide(context);
                    controller.gotoChartPage(controller.pupilModel);
                  },
                  child: Text('${tInMap('pupilPage', 'pupilStatus')}'),
                ),
              ],
            ),
          ],
        )
      ),
    );
  }

  @override
  void dispose() {
    controller.onDispose();
    super.dispose();
  }
  ///========================================================================================================
}

/*
final content = Align(
                            child: SizedBox(
                              width: 260,
                              child: Card(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FlipInX(
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                  onPressed: (){
                                                    OverlayDialog().hide(context);
                                                    controller.gotoChartPage(controller.pupilModel);
                                                    //controller.getUserStatus(controller.pupilModel.userId);
                                                  },
                                                  child: Text('${tInMap('pupilPage', 'pupilStatus')}'),
                                              ),
                                            ),
                                          ),

                                          SizedBox(height: 15,),
                                          FlipInX(
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: (){
                                                  OverlayDialog().hide(context);
                                                  controller.gotoProgramsPage();
                                                },
                                                child: Text('${tInMap('pupilPage', 'pupilProgram')}'),
                                              ),
                                            ),
                                          ),

                                          SizedBox(height: 15,),
                                          FlipInX(
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: (){
                                                  OverlayDialog().hide(context);
                                                  controller.gotoExecutePage();
                                                },
                                                child: Text('${tInMap('pupilPage', 'executionProcess')}'),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: 20,),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(10, 0, 0, 10),
                                      child: Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Material(
                                          color: AppThemes.currentTheme.primaryColor,
                                          shape: CircleBorder(),
                                          child: IconButton(
                                              onPressed: (){
                                                OverlayDialog().hide(context);
                                              },
                                              padding: EdgeInsets.all(4),
                                              splashRadius: 1,
                                              constraints: BoxConstraints.tightFor(),
                                              iconSize: 25,
                                              icon: Icon(IconList.close, color: Colors.white,)
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                          final view = OverlayScreenView(content: content, backgroundColor: Colors.black54,);

                          OverlayDialog().show(context, view, canBack: true);
 */