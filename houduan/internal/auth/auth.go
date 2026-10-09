package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"strings"

	"golang.org/x/crypto/scrypt"
)

const (
	scryptN = 16384
	scryptR = 8
	scryptP = 1
	scryptL = 32
)

func HashToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

func NewToken(n int) (string, error) {
	buf := make([]byte, n)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(buf), nil
}

func NewUUID() (string, error) {
	buf := make([]byte, 16)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	buf[6] = (buf[6] & 0x0f) | 0x40
	buf[8] = (buf[8] & 0x3f) | 0x80
	return fmtUUID(buf), nil
}

func fmtUUID(b []byte) string {
	return hex.EncodeToString(b[0:4]) + "-" +
		hex.EncodeToString(b[4:6]) + "-" +
		hex.EncodeToString(b[6:8]) + "-" +
		hex.EncodeToString(b[8:10]) + "-" +
		hex.EncodeToString(b[10:16])
}

// HashPassword stores scrypt$<hex salt>$<hex key>.
// The salt string itself is the scrypt salt, matching the previous backend.
func HashPassword(password string) (string, error) {
	saltRaw := make([]byte, 16)
	if _, err := rand.Read(saltRaw); err != nil {
		return "", err
	}
	salt := hex.EncodeToString(saltRaw)
	sum, err := scrypt.Key([]byte(password), []byte(salt), scryptN, scryptR, scryptP, scryptL)
	if err != nil {
		return "", err
	}
	return "scrypt$" + salt + "$" + hex.EncodeToString(sum), nil
}

func VerifyPassword(password, stored string) bool {
	algo, rest, ok := strings.Cut(stored, "$")
	if !ok || algo != "scrypt" {
		return false
	}
	salt, hash, ok := strings.Cut(rest, "$")
	if !ok || salt == "" || hash == "" {
		return false
	}
	expected, err := hex.DecodeString(hash)
	if err != nil {
		return false
	}
	actual, err := scrypt.Key([]byte(password), []byte(salt), scryptN, scryptR, scryptP, scryptL)
	if err != nil || len(actual) != len(expected) {
		return false
	}
	return subtle.ConstantTimeCompare(actual, expected) == 1
}

func SafeEqual(left, right string) bool {
	a := []byte(left)
	b := []byte(right)
	if len(a) != len(b) {
		return false
	}
	return subtle.ConstantTimeCompare(a, b) == 1
}

func BearerToken(header string) string {
	parts := strings.SplitN(strings.TrimSpace(header), " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return ""
	}
	return strings.TrimSpace(parts[1])
}
