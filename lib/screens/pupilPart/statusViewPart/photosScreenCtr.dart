import 'dart:io';

import 'package:flutter/material.dart';

import 'package:iris_tools/features/overlayDialog.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '/abstracts/viewController.dart';
import '/models/dataModels/photoDataModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/pupilPart/statusViewPart/photosScreen.dart';
import '/system/requester.dart';
import '/tools/centers/httpCenter.dart';
import '/views/brokenImageView.dart';

class PhotosScreenCtr implements ViewController {
  late PhotoScreenState state;
  Requester? commonRequester;
  late UserModel pupilUser;
  late List<PhotoDataModel> frontPhotos;
  late List<PhotoDataModel> backPhotos;
  late List<PhotoDataModel> sidePhotos;

  @override
  void onInitState<E extends State>(E state){
    this.state = state as PhotoScreenState;

    commonRequester = Requester();
    commonRequester!.requestPath = RequestPath.SetData;

    pupilUser = state.widget.pupilUser;

    updatePhotos();
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester?.httpRequester);
  }

  void updatePhotos(){
    frontPhotos = pupilUser.fitnessDataModel.frontPhotoNodes;
    backPhotos = pupilUser.fitnessDataModel.backPhotoNodes;
    sidePhotos = pupilUser.fitnessDataModel.sidePhotoNodes;
  }
  ///========================================================================================================
  void tryAgain(State state){
    if(state is PhotoScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
    }
  }

  void openGallery(List<PhotoDataModel> list, int idx){
    final pageController = PageController(initialPage: idx,);

    final Widget gallery = PhotoViewGallery.builder(
      scrollPhysics: BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      enableRotation: false,
      gaplessPlayback: true,
      reverse: false,
      //customSize: Size(AppSizes.getScreenWidth(state.context), 200),
      itemCount: list.length,
      pageController: pageController,
      //onPageChanged: onPageChanged,
      backgroundDecoration: BoxDecoration(
        color: Colors.black,
      ),
      builder: (BuildContext context, int index) {
        final ph = list.elementAt(index);

        return PhotoViewGalleryPageOptions(
            imageProvider: FileImage(File(ph.getPath()?? ''),),// NetworkImage(ph.uri),
            heroAttributes: PhotoViewHeroAttributes(tag: 'photo$idx'),
            basePosition: Alignment.center,
            gestureDetectorBehavior: HitTestBehavior.translucent,
            maxScale: 2.0,
            //minScale: 0.5,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, Object error, StackTrace? stackTrace){
              return BrokenImageView();
            }
        );
      },

      loadingBuilder: (context, progress) => Center(
        child: SizedBox(
          width: 70.0,
          height: 70.0,
          child: (progress == null || progress.expectedTotalBytes == null)

              ? CircularProgressIndicator()
              : CircularProgressIndicator(value: progress.cumulativeBytesLoaded / progress.expectedTotalBytes!,),
        ),
      ),
    );

    final osv = OverlayScreenView(
      content: gallery,
      routingName: 'Gallery',
    );

    OverlayDialog().show(state.context, osv);
  }
}
