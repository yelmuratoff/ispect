import 'package:flutter/material.dart';

/// clients will implement this class to provide a wrapped route.
///
/// In some cases we want to wrap our screen with a parent widget usually to provide some values through context,
/// e.g wrapping your route with a custom Theme or a Provider, to do that simply implement AutoRouteWrapper,
/// and have wrappedRoute(context) method return (this) as the child of your wrapper widget
///
/// class ProductsScreen extends StatelessWidget implements RouteWrapper {
///   @override
///   Widget wrappedRoute(BuildContext context) {
///   return Provider(create: (ctx) => ProductsBloc(), child: this);
///   }
abstract class RouteWrapper {
  /// clients will implement this method to return their wrapped routes
  Widget wrappedRoute(BuildContext context);
}
