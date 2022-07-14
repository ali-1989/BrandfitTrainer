import 'package:flutter/material.dart';

import 'package:iris_tools/widgets/irisImageView.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/pupilPart/statusViewPart/photosScreenCtr.dart';
import '/system/extensions.dart';
import '/tools/app/appSizes.dart';
import '/tools/dateTools.dart';
import '/views/brokenImageView.dart';
import '/views/preWidgets.dart';

class PhotoScreen extends StatefulWidget {
  static const screenName = 'PhotoScreen';
  final UserModel pupilUser;

  PhotoScreen({required this.pupilUser, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PhotoScreenState();
  }
}
///=========================================================================================================
class PhotoScreenState extends StateBase<PhotoScreen> {
  var stateController = StateXController();
  var controller = PhotosScreenCtr();


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

  Widget getScaffold() {
    return SizedBox(
      width: AppSizes.getScreenWidth(context),
      height: AppSizes.getScreenHeight(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${context.tC('photos')}'),
        ),
        body: getBody(),
      ),
    );
  }

  Widget getBody() {
    return StateX(
        controller: stateController,
        isMain: true,
        builder: (ctx, ctr, data) {
          return ListView(
            scrollDirection: Axis.vertical,
            children: [
              ...getFront(),
              ...getBack(),
              ...getSide(),
            ],
          );
        });
  }

  ///======================================================================================
  List<Widget> getFront() {
    return [
      SizedBox(height: 10,),
      Text('    ${tC('frontPhoto')}').fs(15).bold(),
      SizedBox(height: 10,),

      Card(
        color: Colors.grey.shade400,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.frontPhotos.length,
              itemBuilder: (ctx, idx) {
                final ph = controller.frontPhotos.elementAt(idx);

                return Stack(
                  children: [
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: Padding(
                        padding: EdgeInsets.all(6.0),
                        child: GestureDetector(
                          onTap: () {
                            controller.openGallery(controller.frontPhotos, idx - 1);
                          },
                          child: IrisImageView(
                            beforeLoadWidget: PreWidgets.flutterLoadingWidget$Center(),
                            errorWidget: BrokenImageView(),
                            url: ph.uri,
                            imagePath: ph.getPath(),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                              DateTools.dateRelativeByAppFormat(ph.utcDate)
                          ).bold().color(Colors.white).wrapBackground(),
                        )
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> getBack() {
    return [
      SizedBox(height: 10,),
      Text('    ${tC('backPhoto')}').fs(15).bold(),
      SizedBox(height: 10,),

      Card(
        color: Colors.grey.shade400,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.backPhotos.length,
              itemBuilder: (ctx, idx) {
                final ph = controller.backPhotos.elementAt(idx);

                return Stack(
                  children: [
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: Padding(
                        padding: EdgeInsets.all(6.0),
                        child: GestureDetector(
                          onTap: () {
                            controller.openGallery(controller.backPhotos, idx);
                          },
                          child: IrisImageView(
                            beforeLoadWidget: PreWidgets.flutterLoadingWidget$Center(),
                            errorWidget: BrokenImageView(),
                            url: ph.uri,
                            imagePath: ph.getPath(),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                              DateTools.dateRelativeByAppFormat(ph.utcDate)
                          ).bold().color(Colors.white).wrapBackground(),
                        )
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> getSide() {
    return [
      SizedBox(height: 10,),
      Text('    ${tC('sidePhoto')}').fs(15).bold(),
      SizedBox(height: 10,),

      Card(
        color: Colors.grey.shade400,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.sidePhotos.length,
              itemBuilder: (ctx, idx) {
                final ph = controller.sidePhotos.elementAt(idx);

                return Stack(
                  children: [
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: Padding(
                        padding: EdgeInsets.all(6.0),
                        child: GestureDetector(
                          onTap: () {
                            controller.openGallery(controller.sidePhotos, idx - 1);
                          },

                          child: IrisImageView(
                            beforeLoadWidget: PreWidgets.flutterLoadingWidget$Center(),
                            errorWidget: BrokenImageView(),
                            url: ph.uri,
                            imagePath: ph.getPath(),
                            onDownloadFn: (bytes, path) {
                              //Deeply.insertToListMap(['SidePhoto'], state.user.fitnessStatusJs!, 'Uri', ph.uri, {'path': path});
                              //Session.sinkUserInfo(state.user);
                            },
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                              DateTools.dateRelativeByAppFormat(ph.utcDate)
                          ).bold().color(Colors.white).wrapBackground(),
                        )
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ];
  }
}
