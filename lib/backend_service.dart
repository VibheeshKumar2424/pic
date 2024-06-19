import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

final _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': '*',
};

Future<Response> _verifyLogin(Request request) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final applicationNumber = data['application_number'];
    final captchaResponse = data['captcha_response'];

    // Verify CAPTCHA
    const secretKey = 'your_secret_key'; // Replace with your secret key
    final captchaVerifyUrl =
        Uri.parse('https://www.google.com/recaptcha/api/siteverify');
    final captchaResponseResult = await http.post(captchaVerifyUrl, body: {
      'secret': secretKey,
      'response': captchaResponse,
    });

    final captchaVerifyData = jsonDecode(captchaResponseResult.body);
    if (!captchaVerifyData['success']) {
      return Response.forbidden(jsonEncode(
          {'success': false, 'message': 'CAPTCHA verification failed'}));
    }

    // Check application number in PostgreSQL database
    final connection = PostgreSQLConnection(
      'your_db_host',
      5432,
      'your_db_name',
      username: 'your_db_user',
      password: 'your_db_password',
    );
    await connection.open();
    final result = await connection.query(
        'SELECT name FROM users WHERE application_number = @appNumber',
        substitutionValues: {
          'appNumber': applicationNumber,
        });
    await connection.close();

    if (result.isEmpty) {
      return Response.forbidden(jsonEncode(
          {'success': false, 'message': 'Invalid application number'}));
    }

    final name = result[0][0];
    final loginTime = DateTime.now().toIso8601String();
    return Response.ok(
        jsonEncode({'success': true, 'name': name, 'login_time': loginTime}));
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'Server error'}));
  }
}

void main() async {
  final router = Router()..post('/verify_login', _verifyLogin);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(headers: _corsHeaders))
      .addHandler(router);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server listening on port ${server.port}');
}
