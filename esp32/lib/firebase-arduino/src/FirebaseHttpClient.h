#ifndef FIREBASE_HTTP_CLIENT_H
#define FIREBASE_HTTP_CLIENT_H

#include <string>

#include "Arduino.h"
#include "Stream.h"

struct HttpStatus {
  static const int TEMPORARY_REDIRECT = 307;
};

class FirebaseHttpClient {
public:
  static FirebaseHttpClient *create();

  virtual void setReuseConnection(bool reuse) = 0;
  virtual void begin(const std::string &url) = 0;
  virtual void begin(const std::string &host, const std::string &path) = 0;

  virtual void end() = 0;

  virtual void addHeader(const std::string &name, const std::string &value) = 0;
  virtual void collectHeaders(const char *header_keys[],
                              const int header_key_count) = 0;
  virtual std::string header(const std::string &name) = 0;

  virtual int sendRequest(const std::string &method,
                          const std::string &data) = 0;

  virtual std::string getString() = 0;

  virtual Stream *getStreamPtr() = 0;

  virtual std::string errorToString(int error_code) = 0;

protected:
  static const uint16_t kFirebasePort = 443;
};

// static const char kFirebaseFingerprint[] =
//     "B8 4F 40 70 0C 63 90 E0 07 E8 7D BD B4 11 D0 4A EA 9C 90 F6";

static const char *kFirebaseCA =
    "-----BEGIN CERTIFICATE-----\n"
    "MIIEKDCCAxCgAwIBAgIQAQAhJYiw+lmnd+8Fe2Yn3zANBgkqhkiG9w0BAQsFADBC\n"
    "MQswCQYDVQQGEwJVUzEWMBQGA1UEChMNR2VvVHJ1c3QgSW5jLjEbMBkGA1UEAxMS\n"
    "R2VvVHJ1c3QgR2xvYmFsIENBMB4XDTE3MDUyMjExMzIzN1oXDTE4MTIzMTIzNTk1\n"
    "OVowSTELMAkGA1UEBhMCVVMxEzARBgNVBAoTCkdvb2dsZSBJbmMxJTAjBgNVBAMT\n"
    "HEdvb2dsZSBJbnRlcm5ldCBBdXRob3JpdHkgRzIwggEiMA0GCSqGSIb3DQEBAQUA\n"
    "A4IBDwAwggEKAoIBAQCcKgR3XNhQkToGo4Lg2FBIvIk/8RlwGohGfuCPxfGJziHu\n"
    "Wv5hDbcyRImgdAtTT1WkzoJile7rWV/G4QWAEsRelD+8W0g49FP3JOb7kekVxM/0\n"
    "Uw30SvyfVN59vqBrb4fA0FAfKDADQNoIc1Fsf/86PKc3Bo69SxEE630k3ub5/DFx\n"
    "+5TVYPMuSq9C0svqxGoassxT3RVLix/IGWEfzZ2oPmMrhDVpZYTIGcVGIvhTlb7j\n"
    "gEoQxirsupcgEcc5mRAEoPBhepUljE5SdeK27QjKFPzOImqzTs9GA5eXA37Asd57\n"
    "r0Uzz7o+cbfe9CUlwg01iZ2d+w4ReYkeN8WvjnJpAgMBAAGjggERMIIBDTAfBgNV\n"
    "HSMEGDAWgBTAephojYn7qwVkDBF9qn1luMrMTjAdBgNVHQ4EFgQUSt0GFhu89mi1\n"
    "dvWBtrtiGrpagS8wDgYDVR0PAQH/BAQDAgEGMC4GCCsGAQUFBwEBBCIwIDAeBggr\n"
    "BgEFBQcwAYYSaHR0cDovL2cuc3ltY2QuY29tMBIGA1UdEwEB/wQIMAYBAf8CAQAw\n"
    "NQYDVR0fBC4wLDAqoCigJoYkaHR0cDovL2cuc3ltY2IuY29tL2NybHMvZ3RnbG9i\n"
    "YWwuY3JsMCEGA1UdIAQaMBgwDAYKKwYBBAHWeQIFATAIBgZngQwBAgIwHQYDVR0l\n"
    "BBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMA0GCSqGSIb3DQEBCwUAA4IBAQDKSeWs\n"
    "12Rkd1u+cfrP9B4jx5ppY1Rf60zWGSgjZGaOHMeHgGRfBIsmr5jfCnC8vBk97nsz\n"
    "qX+99AXUcLsFJnnqmseYuQcZZTTMPOk/xQH6bwx+23pwXEz+LQDwyr4tjrSogPsB\n"
    "E4jLnD/lu3fKOmc2887VJwJyQ6C9bgLxRwVxPgFZ6RGeGvOED4Cmong1L7bHon8X\n"
    "fOGLVq7uZ4hRJzBgpWJSwzfVO+qFKgE4h6LPcK2kesnE58rF2rwjMvL+GMJ74N87\n"
    "L9TQEOaWTPtEtyFkDbkAlDASJodYmDkFOA/MgkgMCkdm7r+0X8T/cKjhf4t5K7hl\n"
    "MqO5tzHpCvX2HzLc\n"
    "-----END CERTIFICATE-----\n";

#endif // FIREBASE_HTTP_CLIENT_H
