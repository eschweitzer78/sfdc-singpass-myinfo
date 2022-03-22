public class Singpass_MyInfoClient {
  static final String SIGNATURE_METHOD = 'RS256';
  static final String CRYPTO_SIGNATURE_ALGO = 'RSA-SHA256';
  static final Integer NONCE_LENGTH = 16;
  static final String NONCE_POSSIBLE_CHARS = '0123456789abcdef';

  static final String GRANT_TYPE = 'authorization_code';

  String method;
  String endpointUrl;
  String appId;
  String clientId;
  String clientSecret;
  String keyDevName;
  Map<String, String> params;
  String bearerToken;
  
  public Singpass_MyInfoClient(String method, String endpointUrl, String appId, String clientId, String clientSecret, String keyDevName) {
    this.method = method; // HTTP Method
    this.endpointUrl = endpointUrl;
    this.appId = appId;
    this.clientId = clientId;
    this.clientSecret = clientSecret;
    this.keyDevName = keyDevName;

    this.params = new Map<String, String>();
  }

  public Singpass_MyInfoClient setMethod(String method) {
    this.method = method;
    return this;
  }

  public Singpass_MyInfoClient setEndpointUrl(String endpointUrl) {
    this.endpointUrl = endpointUrl;
    return this;
  } 

  public Singpass_MyInfoClient setAppId(String appId) {
    this.appId = appId;
    return this;
  }

  public Singpass_MyInfoClient setClientId(String clientId) {
    this.clientId = clientId;
    return this;
  }

  public Singpass_MyInfoClient setClientSecret(String clientSecret) {
    this.clientSecret = clientSecret;
    return this;
  }

  public Singpass_MyInfoClient setKeyDevName(String keyDevName) {
    this.keyDevName = keyDevName;
    return this;
  }

  public Singpass_MyInfoClient setBearerToken(String bearerToken) {
    this.bearerToken = bearerToken;
    return this;
  }

  public Singpass_MyInfoClient clearParams() {
    this.params.clear();
    return this;
  }

  public Singpass_MyInfoClient setParams(Map<String, String> params) {
    this.params.clear();
    this.params.putAll(params);
    return this;
  }

  public Singpass_MyInfoClient addParam(String key, String value) {
    this.params.put(key, value);
    return this;
  }

  static String generateNonce() {    
    String nonce = '';
    
    while (nonce.length() < NONCE_LENGTH) {
      Integer i = Math.mod(Math.abs(Crypto.getRandomInteger()), NONCE_POSSIBLE_CHARS.length());
      nonce += NONCE_POSSIBLE_CHARS.substring(i, i + 1);
    }
    
    return EncodingUtil.convertToHex(Blob.valueOf(nonce));
  }

  static long generateTimestamp() {
    return Datetime.now().getTime();
  }    
  
  public static String generateAuthURL(String authBaseUrl, String redirectUri, String clientId, String purpose, String attributes, String scope, String state) {
    // TODO: fix state to avoid replay attacks
    return authBaseUrl +
      '?attributes=' + EncodingUtil.urlEncode(attributes, 'UTF-8') +
      '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') +
      '&purpose=' + EncodingUtil.urlEncode(purpose, 'UTF-8') +
      '&redirect_uri=' + EncodingUtil.urlEncode(redirectUri, 'UTF-8') +
      '&scope=' + EncodingUtil.urlEncode(scope, 'UTF-8') +
      '&state='+ EncodingUtil.urlEncode(state, 'UTF-8');
  }

  String generateParamsString() {
    Map<String, String> paramsCopy = new Map<String, String>();
    paramsCopy.putAll(params);

    List<String> sortedKeys = new List<String>();
    sortedKeys.addAll(paramsCopy.keySet());
    sortedKeys.sort();
    
    if (this.method == 'GET') {
      for (Integer index = 0; index < sortedKeys.size(); index++) {
        sortedKeys[index] += '=' + EncodingUtil.urlEncode(paramsCopy.get(sortedKeys[index]), 'UTF-8');
      }
    } else if (this.method == 'POST') {
      for (Integer index = 0; index < sortedKeys.size(); index++) {
        sortedKeys[index] += '=' + paramsCopy.get(sortedKeys[index]);
      }
    }

    return String.join(sortedKeys, '&');
  }
      
  public String generateAuthorizationHeader(Long timestamp, String nonce) {
  return 'PKI_SIGN ' +
    'app_id="' + this.appId + '",' +
    'timestamp="' + String.valueOf(timestamp) + '",' +
    'nonce="' + nonce + '",' +
    'signature_method="' + SIGNATURE_METHOD +'",' +
    'signature="' + this.generateSignature(timestamp, nonce) + '"' +
    ((this.bearerToken != null) ? ',Bearer ' + this.bearerToken : '');
}  

  String generateSignature(Long timestamp, String nonce) {
    Map<String, String> paramsCopy = new Map<String, String>();
    paramsCopy.putAll(params);
    
    paramsCopy.put('timestamp', String.valueOf(timestamp));
    paramsCopy.put('nonce', nonce);
    paramsCopy.put('app_id', this.appId);
    paramsCopy.put('signature_method', SIGNATURE_METHOD);

    List<String> paramsArray = new List<String>();        
    List<String> sortedKeys = new List<String>();
    sortedKeys.addAll(paramsCopy.keySet());
    sortedKeys.sort();
    
    for (String key : sortedKeys) {
      paramsArray.add(key + '=' + paramsCopy.get(key));
    }
    
    Blob data = Blob.valueOf(this.method + '&' + endpointUrl + '&' + String.join(paramsArray, '&'));

    try {
      Blob rs256sig = System.Crypto.signWithCertificate(CRYPTO_SIGNATURE_ALGO, data, keyDevName);
      return EncodingUtil.base64Encode(rs256sig);
    } catch(Exception ex) {
      System.debug('Exception---' +ex.getMessage());
      return null;
    }       
  }


  public class HttpErrorException extends Exception {}
  public class NoTokenException extends Exception {}
  public class InvalidTokenException extends Exception {}

  public Singpass_JWT performAuthCallout(String code, String redirectUri, String state) {
    HttpRequest req = new HttpRequest();
    req.setMethod(this.method);
    req.setEndpoint(this.endpointUrl);

    addParam('client_id', this.clientId);
    addParam('client_secret', this.clientSecret);
    addParam('code', code);
    addParam('grant_type', GRANT_TYPE);
    addParam('redirect_uri', redirectUri);
    addParam('state', state);
    
    String body = generateParamsString();
    String authHeader = generateAuthorizationHeader(generateTimestamp(), generateNonce());
    
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.setHeader('Cache-Control', 'no-cache');
    req.setHeader('Authorization', authHeader);
    req.setHeader('Accept', '*/*');
    req.setHeader('Content-Length', String.valueOf(body.length()));
    
    req.setBody(body);
    req.setTimeout(60000);
                
    Http callout = new Http();
    HttpResponse response = callout.send(req);

    if (response.getStatusCode() < 200 || response.getStatusCode() > 201) {
      throw new HttpErrorException();
    }

    String token;

    try {
      String responseText = response.getBody();
      Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseText);  
      token =  String.valueOf(responseMap.get('access_token'));
    } catch (Exception e) {
        throw new NoTokenException();
    }

    Singpass_JWT jwt = new Singpass_JWT(token);

    if (jwt.verify() == false) {
      throw new InvalidTokenException();
    }

    this.bearerToken = token;

    return jwt;
  }


  public HttpResponse performPersonCallout() {
    HttpRequest req = new HttpRequest();
    req.setMethod(this.method);

    String reqParams = generateParamsString();
    String authHeader = generateAuthorizationHeader(generateTimestamp(), generateNonce());
    req.setEndpoint(this.endpointUrl + '?' + reqParams);
    
    req.setHeader('Cache-Control', 'no-cache');
    req.setHeader('Authorization', authHeader);
    req.setHeader('Accept', '*/*');
    
    req.setTimeout(60000);
                
    Http callout = new Http();
    return callout.send(req);
  }
}
