

abstract class Routes {
  Routes._();
  static const DASHBOARD = _Paths.DASHBOARD;
  static const LOGIN = _Paths.LOGIN;
  static const REGISTER = _Paths.REGISTER;
  static const ARTICLE_DETAIL = _Paths.ARTICLE_DETAIL;
  static const PROFILE = _Paths.PROFILE;
}

abstract class _Paths {
  _Paths._();
  static const DASHBOARD = '/dashboard';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const ARTICLE_DETAIL = '/article-detail';
  static const PROFILE = '/profile';
}