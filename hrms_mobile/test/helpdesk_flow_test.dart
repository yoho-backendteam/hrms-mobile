import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_mobile/features/helpdesk/domain/models/ticket_model.dart';

void main() {
  group('Helpdesk & TicketModel Unit Tests', () {
    test('TicketModel parses correctly from backend JSON', () {
      final json = {
        'id': 'tkt-1001',
        'ticketNumber': '#HD-1001',
        'title': 'VPN Access Request for Remote Work',
        'description': 'Need Cisco AnyConnect credentials for remote network access.',
        'category': 'Software & Access Permissions',
        'priority': 'HIGH',
        'status': 'OPEN',
        'createdAt': '2026-08-30T10:00:00.000Z',
        'comments': [
          {
            'id': 'cm-1',
            'ticketId': 'tkt-1001',
            'authorName': 'System Admin',
            'message': 'Your request has been routed to IT Security.',
            'createdAt': '2026-08-30T10:15:00.000Z',
          }
        ]
      };

      final ticket = TicketModel.fromJson(json);

      expect(ticket.id, 'tkt-1001');
      expect(ticket.ticketNumber, '#HD-1001');
      expect(ticket.title, 'VPN Access Request for Remote Work');
      expect(ticket.priority, 'HIGH');
      expect(ticket.status, 'OPEN');
      expect(ticket.category, 'Software & Access Permissions');
      expect(ticket.comments.length, 1);
      expect(ticket.comments.first.authorName, 'System Admin');
    });

    test('TicketCommentModel parses correctly with fallback values', () {
      final json = {
        'id': 'cm-2',
        'message': 'Issue resolved.',
      };

      final comment = TicketCommentModel.fromJson(json);

      expect(comment.id, 'cm-2');
      expect(comment.message, 'Issue resolved.');
      expect(comment.authorName, 'Support Staff');
      expect(comment.isInternal, false);
    });
  });
}
