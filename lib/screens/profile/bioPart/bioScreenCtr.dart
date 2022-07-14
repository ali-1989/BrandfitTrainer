import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:iris_pic_editor/pic_editor.dart';
import 'package:iris_tools/api/helpers/fileHelper.dart';
import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/api/helpers/jsonHelper.dart';
import 'package:iris_tools/api/helpers/pathHelper.dart';
import 'package:iris_tools/features/overlayDialog.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '/abstracts/viewController.dart';
import '/models/dataModels/photoDataModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/profile/bioPart/bioScreen.dart';
import '/system/enums.dart';
import '/system/icons.dart';
import '/system/keys.dart';
import '/system/queryFiltering.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appManager.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/directoriesCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/sheetCenter.dart';
import '/tools/centers/snackCenter.dart';
import '/tools/permissionTools.dart';
import '/tools/uriTools.dart';
import '/views/brokenImageView.dart';
import '/views/loadingScreen.dart';

class BioScreenCtr implements ViewController {
  late BioScreenState state;
  late Requester commonRequester;
  late FilterRequest filterRequest;
  late UserModel user;
  late quill.QuillController bioCtr;
  String? biography;
  List<PhotoDataModel> photos = [];

  @override
  void onInitState<E extends State>(E state){
    this.state = state as BioScreenState;

    state.stateController.mainState = StateXController.state$loading;
    bioCtr = quill.QuillController.basic();
    user = Session.getLastLoginUser()!;
    filterRequest = FilterRequest();
    filterRequest.limit = 100;

    commonRequester = Requester();

    prepareFilterOptions();
    requestBio();
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
  }

  void prepareFilterOptions(){
    filterRequest.addSearchView(SearchKeys.titleKey);
  }
  ///========================================================================================================
  void openGallery(int idx){
    final pageController = PageController(initialPage: idx,);

    final Widget gallery = PhotoViewGallery.builder(
      scrollPhysics: BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      enableRotation: false,
      gaplessPlayback: true,
      reverse: false,
      //customSize: Size(AppSizes.getScreenWidth(state.context), 200),
      itemCount: photos.length,
      pageController: pageController,
      //onPageChanged: onPageChanged,
      backgroundDecoration: BoxDecoration(
        color: Colors.black,
      ),
      builder: (BuildContext context, int index) {
        final ph = photos.elementAt(index);

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

  void addPhoto(){
    final items = <Map>[];

    items.add({
      'title': '${state.t('camera')}',
      'icon': IconList.camera,
      'fn': (){
        PermissionTools.requestCameraStoragePermissions().then((value) {
          if(value == PermissionStatus.granted){
            ImagePicker().pickImage(source: ImageSource.camera).then((value) {
              if(value == null) {
                return;
              }

              editImage(value.path);
            });
          }
        });
      }
    });

    items.add({
      'title': '${state.t('gallery')}',
      'icon': IconList.gallery,
      'fn': (){
        PermissionTools.requestStoragePermission().then((value) {
          if(value == PermissionStatus.granted){
            ImagePicker().pickImage(source: ImageSource.gallery).then((value) {
              if(value == null) {
                return;
              }

              editImage(value.path);
            });
          }
        });
      }
    });


    Widget genView(elm){
      return ListTile(
        title: Text(elm['title']),
        leading: Icon(elm['icon']),
        onTap: (){
          SheetCenter.closeSheetByName(state.context, 'EditMenu');
          elm['fn']?.call();
        },
      );
    }

    SheetCenter.showSheetMenu(state.context,
        items.map(genView).toList(),
        'EditMenu');
  }

  void editImage(String imgPath){
    final editOptions = EditOptions.byPath(imgPath);
    editOptions.cropBoxInitSize = Size(200, 170);

    void onOkButton(EditOptions op) async {
      final pat = DirectoriesCenter.getSavePathByPath(SavePathType.USER_PROFILE, imgPath)!;

      FileHelper.createNewFileSync(pat);
      FileHelper.writeBytesSync(pat, editOptions.imageBytes!);

      uploadPhoto(pat);
    }

    editOptions.callOnResult = onOkButton;
    final ov = OverlayScreenView(content: PicEditor(editOptions), backgroundColor: Colors.black);
    OverlayDialog().show(state.context, ov);
  }

  void afterUpload(String filePath, Map map) async {
    final String uri = map[Keys.fileUri]?? '';
    File? newFile;
    PhotoDataModel? find;

    // rename to server name
    {
      final newName = PathHelper.getFileName(uri);
      final newFileAddress = PathHelper.getParentDirPath(filePath) + PathHelper.getSeparator() + newName;

      newFile = FileHelper.renameSyncSafe(filePath, newFileAddress);
    }

    try {
      find = photos.firstWhere((e) => e.uri == uri);
    }
    catch (e){}

    if(find != null){
      find.localPath = newFile.path;
    }

    await LoadingScreen.hideLoading(state.context);

    state.stateController.updateMain();
    SnackCenter.showSnack$successOperation(state.context);
  }

  void uploadPhoto(String filePath) {
    final partName = 'BioPhoto';
    final fileName = PathHelper.getFileName(filePath);

    final js = <String, dynamic>{};
    js[Keys.request] = 'UpdateBioPhoto';
    js[Keys.forUserId] = user.userId;
    js[Keys.fileName] = fileName;
    js[Keys.partName] = partName;

    AppManager.addAppInfo(js);

    commonRequester.bodyJson = null;
    commonRequester.requestPath = RequestPath.SetData;

    commonRequester.httpItem.addBodyField(Keys.jsonHttpPart, JsonHelper.mapToJson(js));
    commonRequester.httpItem.addBodyFile(partName, fileName, FileHelper.getFile(filePath));


    commonRequester.httpRequestEvents.onFailState = (req) async {
      // for before onFailState, dont remove this
    };

    commonRequester.httpRequestEvents.onNetworkError = (req) async {
      await LoadingScreen.hideLoading(state.context);
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
    };

    commonRequester.httpRequestEvents.onResponseError = (req, isOk) async {
      await LoadingScreen.hideLoading(state.context);

      if(isOk){
        SnackCenter.showSnack$errorInServerSide(state.context);
      } else {
        SnackCenter.showSnack$serverNotRespondProperly(state.context);
      }
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      await LoadingScreen.hideLoading(state.context);
      SnackCenter.showSnack$errorInServerSide(state.context);

      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      final photoData = PhotoDataModel();
      photoData.uri = data[Keys.fileUri];
      photos.add(photoData);

      afterUpload(filePath, data);
    };

    LoadingScreen.showLoading(state.context, canBack: false);
    commonRequester.request(state.context);
  }

  void deleteDialog(PhotoDataModel photo){
    final desc = state.tC('wantToDeleteThisItem')!;

    void yesFn(){
      deletePhoto(photo);
    }

    DialogCenter().showYesNoDialog(state.context, desc: desc, yesFn: yesFn,);
  }

  void deletePhoto(PhotoDataModel photo) {
    final js = <String, dynamic>{};
    js[Keys.request] = 'DeleteBioPhoto';
    js[Keys.userId] = user.userId;
    js[Keys.imageUri] = photo.uri;

    commonRequester.requestPath = RequestPath.SetData;
    commonRequester.bodyJson = js;

    commonRequester.httpRequestEvents.onFailState = (req) async {
      await LoadingScreen.hideLoading(state.context);
      SnackCenter.showSnack$OperationFailed(state.context);
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      await LoadingScreen.hideLoading(state.context);

      try {
        photos.removeWhere((e) => e.uri == photo.uri);
      }
      catch (e){}

      state.stateController.updateMain();
    };

    LoadingScreen.showLoading(state.context, canBack: false);
    commonRequester.request(state.context);
  }

  void requestBio() {
    FocusHelper.hideKeyboardByService();

    final js = <String, dynamic>{};
    js[Keys.request] = 'GetTrainerBio';
    js[Keys.userId] = user.userId;
    js[Keys.forUserId] = user.userId;
    //js[Keys.filtering] = filterRequest.toMap();

    commonRequester.requestPath = RequestPath.GetData;
    commonRequester.bodyJson = js;

    commonRequester.httpRequestEvents.onFailState = (req) async {
      state.stateController.mainStateAndUpdate(StateXController.state$serverNotResponse);
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      biography = data['bio'];
      final images = data['photos'];
      final domain = data[Keys.domain];

      for(final k in images){
        final name = PathHelper.getFileName(k);
        final pat = DirectoriesCenter.getSavePathByPath(SavePathType.USER_PROFILE, name)!;

        final p = PhotoDataModel();
        p.uri = UriTools.correctAppUrl(k, domain: domain);
        p.localPath = pat;

        photos.add(p);
      }

      if(biography != null && biography!.isNotEmpty) {
        final bioList = JsonHelper.jsonToList(biography)!;

        bioCtr = quill.QuillController(
            document: quill.Document.fromJson(bioList),
            selection: TextSelection.collapsed(offset: 0)
        );
      }

      state.stateController.mainStateAndUpdate(StateXController.state$normal);
    };

    commonRequester.request(state.context);
  }
}
