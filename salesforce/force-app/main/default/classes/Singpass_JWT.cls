public with sharing class Singpass_JWT {
    public class TypeException extends Exception {}
    public class AlgorithmException extends Exception {}

    public class Singpass_JWTHeader {
        public String typ;
        public String alg;
        public String kid;
    }

    public class Singpass_JWTPayload {
        public String sub;
        public String cts;
        public Integer auth_level;
        public String auditTrackingId;
        public String iss;
        public String tokenName;
        public String token_type;
        public String authGrantId;
        public String aud;
        public String nbf;
        public String grant_type;
        public List<String> scope;
        public Long auth_time;
        public String realm;
        public Long exp;
        public Long iat;
        public Integer expires_in;
        public String jti;
    }

    String headerRaw;
    public Singpass_JWTHeader header;
    String payloadRaw;
    public Singpass_JWTPayload payload;
    String payloadJSON;
    String signatureRaw;
    Blob signature;


    public Singpass_JWT(String compactSerializedJWT) {
        List<String> tokenParts = compactSerializedJWT.split('\\.');

        this.headerRaw = tokenParts[0];
        String headerJSON = StringUtils.Base64UrlDecodeBlob(this.headerRaw).toString();
        this.payloadRaw = tokenParts[1];
        this.payloadJSON = StringUtils.Base64UrlDecodeBlob(this.payloadRaw).toString();
        this.signatureRaw = tokenParts[2];
        this.signature = StringUtils.Base64UrlDecodeBlob(this.signatureRaw);

        this.header = (Singpass_JWTHeader) JSON.deserialize(headerJSON, Singpass_JWTHeader.class);
        this.payload = (Singpass_JWTPayload) JSON.deserialize(payloadJSON, Singpass_JWTPayload.class);

        if (this.header.typ != 'JWT') {
            throw new TypeException();
        }

        if (this.header.alg != 'RS256') {
            throw new AlgorithmException();
        }
    }


    public boolean verify() {
      // TODO: verify that this is still the actual Singpass MyInfo public key
      // TODO: consider Setup Certificate Management storage
      //       alternatively the whole verification/decryption could be done in Functions/Hero

      String publicKey =
      'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsGBNIs4nsiHNfLqoR40h' +
      '06We1IvWVaGISvETHKlJATWIURd9wx1bqHZ6tesVmLYqKT776kgxXwVD8NP0Vu+T' +
      'h8C+IF+9fMNOa8/TeowvcqDiIRjL7RId8kmpcmjtIS2G+MolfSbH7CRWVRko4q88' +
      'LMbJUAlglSnFppfQhsEVYlwLtZlHAYy9cl8PcsxPmFUzCUH4Fefyq77BBUPMpzbZ' +
      'LLjlAj97rF1oSQJKHM6RBLcvI+AauRpKe34O3GR9bCCTbkhETVerWsemtFUznr9m' +
      'oOSaDkEMIGA5wDyt12kjKKvbbm+k2Y5TMq1IIQXfhihGAbTttVpmZLYwJda0nemL' +
      '4QIDAQAB';

      String sigBase = this.headerRaw + '.' + this.payloadRaw;
      return Crypto.verify('RSA-SHA256', Blob.valueOf(sigBase), this.signature, EncodingUtil.base64Decode(publicKey));
    }


    public String getToken() {
        return this.headerRaw + '.' + this.payloadRaw + '.' + this.signatureRaw;
    }


}
