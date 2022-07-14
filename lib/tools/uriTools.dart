import 'package:iris_tools/api/helpers/pathHelper.dart';
import 'package:iris_tools/api/helpers/urlHelper.dart';

import '/managers/settingsManager.dart';

class UriTools {
  UriTools._();

  static bool isInternalLink(String? link){
    return link != null && (link.startsWith('/') || link.contains(SettingsManager.settingsModel.httpAddress!));
  }

  static String addHttpIfNeed(String? path){
    if(path == null) {
      return '';
    }

    if(path.contains('http')) {
      return path;
    }

    return 'http://' + path;
  }

  static String correctIfIsInternalUrl(String? path){
    if(path == null) {
      return SettingsManager.settingsModel.httpAddress!;
    }

    if(path.startsWith(RegExp(SettingsManager.settingsModel.httpAddress!))) {
      return path;
    }

    if (!isInternalLink(path)) {
      return path;
    }

    if(path.startsWith('/')) {
      return SettingsManager.settingsModel.httpAddress! + path;
    }

    return SettingsManager.settingsModel.httpAddress! + '/' + path;
  }

  static String? correctAppUrl(String? url, {String? domain}) {
    if(url == null){
      return null;
    }

    domain ??= SettingsManager.settingsModel.httpAddress!;
    url = UrlHelper.decodePathFromDataBase(url)!; //decodeUrl

    if(!url.startsWith('http')) {
      url = domain + '/' + url;
    }
    else {
      if(!url.contains(domain)){
        url = url.replaceFirst(RegExp('http://\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}(:\\d{1,5})?'), '');
        url = domain + url;
      }
    }

    return PathHelper.resolveUrl(url)!;
  }
}