// part of 'dio_body.dart';

// class DioResponseBody extends StatefulWidget {
//   const DioResponseBody({
//     required this.log,
//     required this.method,
//     required this.path,
//     required this.url,
//     required this.statusCode,
//     required this.statusMessage,
//     required this.requestHeaders,
//     required this.data,
//     required this.headers,
//     required this.jsonController,
//   });
//   final ISpectiyData log;
//   final String? method;
//   final String? path;
//   final String? url;
//   final int? statusCode;
//   final String? statusMessage;
//   final Map<String, dynamic>? requestHeaders;
//   final Map<String, dynamic>? data;
//   final Map<String, String>? headers;
//   final JsonController jsonController;

//   @override
//   State<DioResponseBody> createState() => DioResponseBodyState();
// }

// class DioResponseBodyState extends State<DioResponseBody> {
//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) => Padding(
//         padding: const EdgeInsets.all(16),
//         child: DioHTTPBody(
//           dataKey: widget.log.key,
//           method: widget.method,
//           path: widget.path,
//           fullUrl: widget.url,
//           statusCode: widget.statusCode,
//           statusMessage: widget.statusMessage,
//           requestHeaders: widget.requestHeaders,
//           data: widget.data,
//           headers: widget.headers,
//           jsonController: widget.jsonController,
//         ),
//       );
// }
