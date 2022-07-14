import 'package:brandfit_trainer/system/httpProcess.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:iris_pic_editor/pic_editor.dart';
import 'package:iris_tools/api/helpers/fileHelper.dart';
import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/api/helpers/jsonHelper.dart';
import 'package:iris_tools/api/helpers/mathHelper.dart';
import 'package:iris_tools/features/overlayDialog.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '/abstracts/viewController.dart';
import '/models/dataModels/countryModel.dart';
import '/models/dataModels/courseModels/courseModel.dart';
import '/models/dataModels/photoDataModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/commons/currencySelect.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appManager.dart';
import '/tools/app/appNavigator.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/sheetCenter.dart';
import '/tools/centers/snackCenter.dart';
import '/tools/currencyTools.dart';
import '/tools/permissionTools.dart';
import '/views/brokenImageView.dart';
import 'addCourseScreen.dart';

class AddCourseScreenCtr implements ViewController {
  late AddCourseScreenState state;
  late Requester commonRequester;
  late UserModel user;
  late CourseModel courseModel;
  bool exerciseProgramChecked = false;
  bool temporaryStorage = true;
  bool foodProgramChecked = false;
  bool isInEditState = false;
  bool isImageChanged = false;
  late CurrencyModel currencyModel;
  TextEditingController nameCtr = TextEditingController();
  TextEditingController durationCtr = TextEditingController();
  TextEditingController descriptionCtr = TextEditingController();
  TextEditingController priceCtr = TextEditingController();


  @override
  void onInitState<E extends State>(E state){
    this.state = state as AddCourseScreenState;

    user = Session.getLastLoginUser()!;
    currencyModel = user.currencyModel;

    isInEditState = state.widget.courseModel != null;

    if(isInEditState){
      courseModel = state.widget.courseModel!;

      nameCtr.text = courseModel.title;
      durationCtr.text = courseModel.durationDay.toString();
      descriptionCtr.text = courseModel.description;
      priceCtr.text = courseModel.price;
      currencyModel = courseModel.currencyModel;
      temporaryStorage = courseModel.isPrivateShow;
      exerciseProgramChecked = courseModel.hasExerciseProgram;
      foodProgramChecked = courseModel.hasFoodProgram;
    }
    else {
      courseModel = CourseModel();
      durationCtr.text = '30';
    }

    if(currencyModel.currencyCode == null) {
      currencyModel = CurrencyTools.getCurrencyBy('USD', 'US');
      Session.sinkUserInfo(user);
    }

    commonRequester = Requester();
    commonRequester.requestPath = RequestPath.SetData;
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
  }
  ///========================================================================================================
  void tryAgain(State state){
    if(state is AddCourseScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
    }
  }

  void onChangeCurrency() {
    AppNavigator.pushNextPage(state.context,
        CurrencySelectScreen(),
        name: CurrencySelectScreen.screenName).then((map){
      if(map == null) {
        return;
      }

      final currency = map as Map;

      if(currency.isNotEmpty){
        user.currencyModel.currencyCode = currency['currency_code'];
        user.currencyModel.currencySymbol = currency['currency_symbol'];
        user.currencyModel.currencyName = currency['currency_name'];
        user.currencyModel.countryIso = currency['iso'];

        currencyModel = user.currencyModel;
        Session.sinkUserInfo(user);

        state.stateController.updateMain();
      }
    });
  }

  void addPhotoClick(){
    final list = <Widget>[
      SizedBox(height: 10,),
      ListTile(
        leading: Icon(IconList.camera),
        title: Text('${state.tC('camera')}'),
        onTap: (){
          SheetCenter.closeSheetByName(state.context, 'ChoosePhotoSource');

          PermissionTools.requestCameraStoragePermissions().then((value) {
            if(value == PermissionStatus.granted) {
              ImagePicker().pickImage(source: ImageSource.camera).then((value) {
                if(value == null) {
                  return;
                }

                editImage(value.path);
              });
            }
          });
        },
      ),

      ListTile(
        leading: Icon(IconList.gallery),
        title: Text('${state.tC('gallery')}'),
        onTap: (){
          SheetCenter.closeSheetByName(state.context, 'ChoosePhotoSource');

          PermissionTools.requestStoragePermission().then((value) {
            if(value == PermissionStatus.granted) {
              ImagePicker().pickImage(source: ImageSource.gallery).then((value) {
                if(value == null) {
                  return;
                }

                editImage(value.path);
              });
            }
          });
        },
      ),
    ];

    SheetCenter.showSheetMenu(state.context, list, 'ChoosePhotoSource');
  }

  void editImage(String imgPath){
    final editOptions = EditOptions.byPath(imgPath);
    editOptions.cropBoxInitSize = Size(200, 170);

    void onOk(EditOptions op) async {
      final pat = courseModel.imagePath!;
      //pat += PathHelper.getSeparator() + 'co${Generator.generateDateMillWithKey(14)}.jpg';

      FileHelper.createNewFileSync(pat);
      FileHelper.writeBytesSync(pat, editOptions.imageBytes!);

      isImageChanged = true;
      state.stateController.updateMain();
    }

    editOptions.callOnResult = onOk;
    final ov = OverlayScreenView(content: PicEditor(editOptions), backgroundColor: Colors.black);
    OverlayDialog().show(state.context, ov);
  }

  void deleteDialog(){
    final desc = state.tC('wantToDeleteThisItem')!;

    void yesFn(){
      isImageChanged = true;
      FileHelper.deleteSyncSafe(courseModel.imagePath);
      courseModel.imageUri = null;
      state.stateController.updateMain();
    }

    DialogCenter().showYesNoDialog(state.context, desc: desc, yesFn: yesFn,);
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
            imageProvider: FileImage(FileHelper.getFile(ph.getPath()?? ''),),// NetworkImage(ph.uri),
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

  void onSaveClick() {
    FocusHelper.hideKeyboardByService();

    final title = nameCtr.text.trim();
    final desc = descriptionCtr.text.trim();
    final duration = MathHelper.clearToInt(durationCtr.text);
    var price = priceCtr.text.trim();

    if(title.isEmpty || title.length < 5){
      SheetCenter.showSheetOk(state.context, '${state.tInMap('addCoursePage', 'titleMust5Char')}'.localeNum());
      return;
    }

    if(desc.isEmpty || desc.length < 15){
      SheetCenter.showSheetOk(state.context, '${state.tInMap('addCoursePage', 'descriptionMust15Char')}'.localeNum());
      return;
    }

    if(price.isEmpty){
      SheetCenter.showSheetOk(state.context,'${state.tInMap('addCoursePage', 'enterPrice')}');
      return;
    }

    price = MathHelper.clearToDouble(price).toStringAsFixed(0);

    if(price.length > 12){
      SheetCenter.showSheetOk(state.context,'${state.tInMap('addCoursePage', 'enterPriceCorrect')}');
      return;
    }

    var isSelectedOnceProgram = exerciseProgramChecked == true;
    isSelectedOnceProgram |= foodProgramChecked == true;

    if(!isSelectedOnceProgram){
      SheetCenter.showSheetOk(state.context, '${state.tInMap('addCoursePage', 'selectOnceOfProgram')}');
      return;
    }

    if(duration < 1){
      SheetCenter.showSheetOk(state.context, '${state.tInMap('addCoursePage', 'durationNotCorrect')}');
      return;
    }

    courseModel.creatorUserId = user.userId;
    courseModel.title = title;
    courseModel.description = desc;
    courseModel.price = price;
    courseModel.durationDay = duration;
    courseModel.currencyModel = currencyModel;
    courseModel.hasExerciseProgram = exerciseProgramChecked;
    courseModel.hasFoodProgram = foodProgramChecked;
    courseModel.isPrivateShow = temporaryStorage;

    uploadData();
  }

  void uploadData() async {
    FocusHelper.hideKeyboardByUnFocus(state.context);
    String? partName;

    final js = <String, dynamic>{};

    if(FileHelper.existSync(courseModel.imagePath!)) {
      if(isImageChanged) {
        partName = 'CourseBackground';

        commonRequester.httpItem.addBodyFile(partName, 'course', FileHelper.getFile(courseModel.imagePath!));
      }
    }
    else {
      if(isImageChanged && isInEditState) {
        partName = 'delete';
      }
    }


    js[Keys.request] = isInEditState? 'EditCourse': 'AddNewCourse';
    js[Keys.forUserId] = user.userId;
    js[Keys.partName] = partName;
    js['course_js'] = JsonHelper.mapToJson(courseModel.toMap());

    AppManager.addAppInfo(js);
    commonRequester.httpItem.addBodyField(Keys.jsonHttpPart, JsonHelper.mapToJson(js));

    commonRequester.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester.httpRequestEvents.onNetworkError = (req) async {
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
      //state.StateXController.mainStateAndUpdate(StateXController.state$netDisconnect);
    };

    commonRequester.httpRequestEvents.onResponseError = (req, isOk) async {
      if(isOk){
        SnackCenter.showSnack$errorInServerSide(state.context);
      } else {
        SnackCenter.showSnack$serverNotRespondProperly(state.context);
      }
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      if (!HttpProcess.processCommonRequestError(state.context, js)) {
        SnackCenter.showSnack$errorInServerSide(state.context);
      }

      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      await SheetCenter.showSheet$SuccessOperation(state.context).then((value) {
        AppNavigator.pop(state.context, result: true);
      });
    };

    state.showLoading();
    commonRequester.request(state.context);
  }
}
