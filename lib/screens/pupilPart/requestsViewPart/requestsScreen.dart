import 'package:brandfit_trainer/tools/app/appThemes.dart';
import 'package:brandfit_trainer/tools/dateTools.dart';
import 'package:flutter/material.dart';

import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/pupilPart/requestsViewPart/requestsCtr.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/tools/app/appSizes.dart';
import '/views/preWidgets.dart';

class RequestsScreen extends StatefulWidget {
  static const screenName = 'RequestsScreen';
  final UserModel pupilModel;

  RequestsScreen({
    required this.pupilModel,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return RequestsScreenState();
  }
}
///=========================================================================================================
class RequestsScreenState extends StateBase<RequestsScreen> {
  StateXController stateController = StateXController();
  ProgramsCtr controller = ProgramsCtr();

  @override
  void initState() {
    super.initState();

    controller.onInitState(this);
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();
    controller.onBuild();

    return getScaffold();
  }

  @override
  void dispose() {
    stateController.dispose();
    controller.onDispose();

    super.dispose();
  }

  getScaffold() {
    return SizedBox(
      width: AppSizes.getScreenWidth(context),
      height: AppSizes.getScreenHeight(context),

      child: StateX(
        isMain: true,
        controller: stateController,
        builder: (context, ctr, data) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.pupilModel.userName),
            ),
            body: getBody(),
          );
        },
      ),
    );
  }

  getBody() {
    return StateX(
      isSubMain: true,
      controller: stateController,
      builder: (context, ctr, data) {
        switch(ctr.subMainState){
          case StateXController.state$loading:
            return PreWidgets.flutterLoadingWidget$Center();
        }

        if(controller.requestList.isEmpty) {
          return noRequest();
        }

        return getRequestList();
      },
    );
  }
  ///==========================================================================================================
  Widget noRequest(){
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PreWidgets.notFound(),
          SizedBox(height: 40,),
          Text('${tInMap('pupilPage', 'youHaveNoStudents')}').subAlpha(),
        ],
      ),
    );
  }

  Widget getRequestList() {
    return ListView.builder(
        itemCount: controller.requestList.length,
        itemBuilder: (ctx, idx){
          return genItem(idx);
        }
    );
  }

  Widget genItem(int idx){
    final request = controller.requestList[idx];

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(IconList.apps2),

                SizedBox(width: 10,),
                Text(request.title)
                    .boldFont().fsR(2),
              ],
            ),

            SizedBox(height: 10,),
            Row(
              children: [
                Text('${tInMap('programsPage', 'endOfSupport')}: ${DateTools.dateOnlyRelative(request.supportExpireDate)}')
                    .boldFont().alpha(),
              ],
            ),

            Row(
              textDirection: AppThemes.getOppositeDirection(),
              children: [
                TextButton(
                    onPressed: request.supportExpireDate == null? null: (){
                      controller.gotoPupilOperation(request);
                    },
                    child: Text('${tInMap('programsPage', 'pupilOperation')}')
                ),

                /*TextButton(
                    onPressed: (){},
                    child: Text('ff')
                ),*/
              ],
            ),
          ],
        ),
      ),
    );
  }
}


