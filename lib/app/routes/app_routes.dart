

abstract class Routes {
  Routes._();
  static const DASHBOARD = _Paths.DASHBOARD;
  static const LOGIN = _Paths.LOGIN;
  static const REGISTER = _Paths.REGISTER;
  static const ARTICLE_DETAIL = _Paths.ARTICLE_DETAIL;
  static const PROFILE = _Paths.PROFILE;
  static const ARTICLE_CREATE = _Paths.ARTICLE_CREATE;
  static const ARTICLE_EDIT = _Paths.ARTICLE_EDIT;
  static const INTEREST_SELECTION = _Paths.INTEREST_SELECTION;
  static const TOPIC_RECOMMENDATION = _Paths.TOPIC_RECOMMENDATION;
  static const CATEGORY_DETAIL = _Paths.CATEGORY_DETAIL;
  static const AUTHOR_PROFILE = _Paths.AUTHOR_PROFILE;
}

abstract class _Paths {
  _Paths._();
  static const DASHBOARD = '/dashboard';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const ARTICLE_DETAIL = '/article-detail';
  static const PROFILE = '/profile';
  static const ARTICLE_CREATE = '/article-create';
  static const ARTICLE_EDIT = '/article-edit';
  static const INTEREST_SELECTION = '/interest-selection';
  static const TOPIC_RECOMMENDATION = '/topic-recommendation';
  static const CATEGORY_DETAIL = '/category-detail';
  static const AUTHOR_PROFILE = '/author-profile';
}