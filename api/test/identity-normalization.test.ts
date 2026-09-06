/**
 * Identity Normalization Tests
 * 
 * Proves:
 * 1. New actors use lowercase normalized emails
 * 2. Legacy mixed-case participants still recognized
 * 3. Legacy mixed-case creators still recognized
 * 4. Organizer remains creator-only
 * 5. Outsider remains denied
 */

import { getCanonicalUserId } from '../src/domain/auth';
import { isParticipant, isOrganizer } from '../src/domain/khatma';
import { AuthContext } from '../src/middleware/auth';
import { Khatma } from '../src/domain/types';

describe('Identity Normalization', () => {
  describe('getCanonicalUserId', () => {
    it('should normalize email to lowercase', () => {
      const auth: AuthContext = {
        uid: 'uid123',
        email: 'User@Example.COM',
        isAdmin: false,
      };

      const result = getCanonicalUserId(auth);
      expect(result).toBe('user@example.com'); // Normalized
    });

    it('should trim whitespace', () => {
      const auth: AuthContext = {
        uid: 'uid123',
        email: '  user@example.com  ',
        isAdmin: false,
      };

      const result = getCanonicalUserId(auth);
      expect(result).toBe('user@example.com');
    });

    it('should fallback to UID when email missing', () => {
      const auth: AuthContext = {
        uid: 'uid123',
        email: undefined,
        isAdmin: false,
      };

      const result = getCanonicalUserId(auth);
      expect(result).toBe('uid123');
    });
  });

  describe('Legacy Mixed-Case Participant Recognition', () => {
    const legacyKhatma: Khatma = {
      id: 'khatma1',
      createdBy: 'Creator@Legacy.com', // Legacy mixed-case
      participantIds: [
        'Creator@Legacy.com',
        'Alice@Test.COM',
        'Bob@Example.org',
      ],
      members: ['Alice@Test.COM', 'Bob@Example.org'],
      isGroup: true,
      isPublic: false,
      reservationMode: true,
      completedHizbCount: 0,
      creationState: 'ready',
    } as Khatma;

    it('should recognize legacy mixed-case participant with normalized new identity', () => {
      const normalizedUserId = 'alice@test.com'; // NEW actor (normalized)
      const uid = 'uid-alice';

      const result = isParticipant(legacyKhatma, normalizedUserId, uid);
      expect(result).toBe(true); // Legacy "Alice@Test.COM" matches normalized "alice@test.com"
    });

    it('should recognize legacy mixed-case creator as participant', () => {
      const normalizedUserId = 'creator@legacy.com'; // NEW actor
      const uid = 'uid-creator';

      const result = isParticipant(legacyKhatma, normalizedUserId, uid);
      expect(result).toBe(true); // Legacy "Creator@Legacy.com" matches
    });

    it('should recognize legacy mixed-case creator as organizer', () => {
      const normalizedUserId = 'creator@legacy.com'; // NEW actor

      const result = isOrganizer(legacyKhatma, normalizedUserId);
      expect(result).toBe(true); // Legacy "Creator@Legacy.com" matches
    });

    it('should deny outsider even with case variations', () => {
      const outsiderId = 'outsider@example.com';
      const uid = 'uid-outsider';

      const result = isParticipant(legacyKhatma, outsiderId, uid);
      expect(result).toBe(false);
    });
  });

  describe('New Khatma with Normalized Identities', () => {
    const newKhatma: Khatma = {
      id: 'khatma2',
      createdBy: 'creator@new.com', // NEW normalized
      participantIds: [
        'creator@new.com',
        'participant@test.com',
      ],
      members: ['participant@test.com'],
      isGroup: true,
      isPublic: false,
      reservationMode: true,
      completedHizbCount: 0,
      creationState: 'ready',
    } as Khatma;

    it('should recognize participant with exact normalized match', () => {
      const userId = 'participant@test.com';
      const uid = 'uid-participant';

      const result = isParticipant(newKhatma, userId, uid);
      expect(result).toBe(true);
    });

    it('should recognize participant even if input has mixed case', () => {
      // Input might come with mixed case from some legacy flow
      const userId = 'Participant@Test.COM';
      const uid = 'uid-participant';

      const result = isParticipant(newKhatma, userId, uid);
      expect(result).toBe(true); // Normalized comparison works
    });

    it('should recognize creator as organizer', () => {
      const userId = 'creator@new.com';

      const result = isOrganizer(newKhatma, userId);
      expect(result).toBe(true);
    });

    it('should recognize creator as organizer even with mixed case input', () => {
      const userId = 'Creator@New.COM';

      const result = isOrganizer(newKhatma, userId);
      expect(result).toBe(true);
    });

    it('should deny participant from being organizer', () => {
      const userId = 'participant@test.com';

      const result = isOrganizer(newKhatma, userId);
      expect(result).toBe(false); // Only creator is organizer
    });
  });

  describe('Authorization Not Weakened', () => {
    const khatma: Khatma = {
      id: 'khatma3',
      createdBy: 'organizer@test.com',
      participantIds: ['organizer@test.com', 'member@test.com'],
      members: ['member@test.com'],
      isGroup: true,
      isPublic: false,
      reservationMode: true,
      completedHizbCount: 0,
      creationState: 'ready',
    } as Khatma;

    it('should deny completely unrelated user', () => {
      const outsiderId = 'hacker@evil.com';
      const uid = 'uid-hacker';

      const participantResult = isParticipant(khatma, outsiderId, uid);
      const organizerResult = isOrganizer(khatma, outsiderId);

      expect(participantResult).toBe(false);
      expect(organizerResult).toBe(false);
    });

    it('should deny similar but not matching email', () => {
      const similarId = 'member@testing.com'; // Close but not exact
      const uid = 'uid-similar';

      const result = isParticipant(khatma, similarId, uid);
      expect(result).toBe(false);
    });
  });
});
