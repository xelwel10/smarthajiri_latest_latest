// config.dart

class Config {
  static String _homeUrl = 'https://demo.smarthajiri.com';
  static String _splashImage = '';
  static String _token = '';
  static String _appname = 'DemoSmarthajiri';
  static String _appVersion = '0.0.0';
  static String _loginImage = 'assets/logo/logo.png';
  static bool _isBioEnabled = false;
  static bool _hasInternet = true;
  static bool _isFirstLoad = true;
  static bool _updateAvaliable = false;
  static bool _isUpdateDialogOpen = false;
  static bool _stopLoading = false;

  static void setHomeUrl(String homeUrl) {
    _homeUrl = homeUrl;
    if (homeUrl == "https://heliosnepal.smarthajiri.com") {
      _loginImage = "assets/logo/helios.png";
    }
    if (homeUrl == "https://manaramhr.xelwel.com") {
      _loginImage = "assets/logo/manaram.png";
    }
    if (homeUrl == "https://medibiz.xelwel.com") {
      _loginImage = "assets/logo/medibiz.jpg";
    }
    if (homeUrl == "https://digi.smarthajiri.com") {
      _loginImage = "assets/logo/digi.png";
    }
    if (homeUrl == "https://hrm.gmc.edu.np") {
      _loginImage = "assets/logo/gmc.png";
    }
  }

  static String getHomeUrl() {
    return _homeUrl;
  }

  static void setSplashImage(String img) {
    _splashImage = img;
  }

  static String getSplashImage() {
    return _splashImage;
  }

  static void setFirstLoad(bool firstLoad) {
    _isFirstLoad = firstLoad;
  }

  static String getApkName() {
    return _appname;
  }

  static void setApkName(String an) {
    _appname = an;
  }

  static String getAppVersion() {
    return _appVersion;
  }

  static void setAppVersion(String av) {
    _appVersion = av;
  }

  static bool getFirstLoad() {
    return _isFirstLoad;
  }

  static void setLoginImage(String img) {
    _loginImage = img;
  }

  static String getLoginImage() {
    return _loginImage;
  }

  static void setToken(String token) {
    _token = token;
  }

  static String getToken() {
    return _token;
  }

  static void setBio(bool bio) {
    _isBioEnabled = bio;
  }

  static bool getBio() {
    return _isBioEnabled;
  }

  static void hasInternet(bool net) {
    _hasInternet = net;
  }

  static bool getInternet() {
    return _hasInternet;
  }

  static void setupdateAvailable(bool update) {
    _updateAvaliable = update;
  }

  static bool getUpdateAvailable() {
    return _updateAvaliable;
  }

  static void setIsUpdateDialogopen(bool update) {
    _isUpdateDialogOpen = update;
  }

  static bool isUpdateDialogopen() {
    return _isUpdateDialogOpen;
  }

  static void setStopLoading(bool loading) {
    _stopLoading = loading;
  }

  static bool getStopLoading() {
    return _stopLoading;
  }
}
