public class Singpass_MyInfoController {
  // TODO: API Redirect - Use your Lightning Tab or Lightning community URL
  // this needs to match the redirect uri shared with Singpass during enrolment
  static final String REDIRECT_URI = 'https://your-community-base/s/my-profile';

  // TODO: change for production
  static final String AUTH_URL = 'https://test.api.myinfo.gov.sg/com/v3/authorise';
  static final String TOKEN_URL = 'https://test.api.myinfo.gov.sg/com/v3/token';
  static final String PERSONAPI_URL = 'https://test.api.myinfo.gov.sg/com/v3/person';

  // TODO: add to scope to get more data points from Singpass MyInfo
  static final String SCOPE = 'mobileno';
  static final String ATTRIBUTES = 'mobileno';

  // TODO: change these to reflect values given to you by Singpass on enrolment
  static final String APP_ID = 'BRING-YOUR-OWN-Singpass-MYINFO-APPID';
  static final String CLIENT_ID = 'BRING-YOUR-OWN-Singpass-CLIENTID';
  static final String CLIENT_SECRET = 'BRING-YOUR-OWN-Singpass-CLIENT-SECRET';
  static final String APP_NAME_CLEARTEXT = 'YOUR-NAME';

  // TODO: change this to the developer name of the RSA certificate you registered with Singpass.
  static final String KEY_DEV_NAME = 'NAME-OF-YOUR-CERT-IN-SETUP-CERT-MANAGEMENT';

  
  @AuraEnabled
  public static String createAuthURL(String redirectUri) {
      try {
      // TODO: generate state dynamically to avoid replay attacks
      String state = 'af121bce3?';

          return Singpass_MyInfoClient.generateAuthURL(AUTH_URL, redirectUri, CLIENT_ID, APP_NAME_CLEARTEXT, ATTRIBUTES, SCOPE, state);
      } catch(Exception e) {
          throw new AuraHandledException(e.getMessage());
      }  
  }
  
  public class GetAccessTokenResponse {
      @AuraEnabled 
      public String token;

      @AuraEnabled 
      public String sub;

      public GetAccessTokenResponse(String token, String sub) {
          this.token = token;
          this.sub = sub;
      }
  }

  @AuraEnabled
  public static GetAccessTokenResponse getAccessToken(String code) {
      try {
        // TODO: generate state dynamically to avoid replay attacks
        // TODO: once could pack additional info in the state, e.g. as a JWT with further details on what needs to be done upon callback
        //       While the state expected by Singpass may have length limitations that make a JWT impractical, a unique transaction number
        //       could be used to save the context in a record or platform cache.
        String state = 'af121bce3?';
          Singpass_MyInfoClient client = new Singpass_MyInfoClient('POST', TOKEN_URL, APP_ID, CLIENT_ID, CLIENT_SECRET, KEY_DEV_NAME);            
          Singpass_JWT jwt = client.performAuthCallout(code, REDIRECT_URI, state);
          
          return new GetAccessTokenResponse(jwt.getToken(), jwt.payload.sub);
      } catch(Exception e) {
          throw new AuraHandledException(e.getMessage());
      }  
  }

  @AuraEnabled
  public static MyInfoResBody getPerson(String token, String sub) {
      try {
          String personApiUrl = PERSONAPI_URL + '/' + sub + '/';

          Singpass_MyInfoClient client = new Singpass_MyInfoClient('GET', personApiUrl, APP_ID, CLIENT_ID, CLIENT_SECRET, KEY_DEV_NAME);
          client.setBearerToken(token)
                .addParam('attributes', ATTRIBUTES)
                .addParam('client_id', CLIENT_ID);


          HttpResponse response = client.performPersonCallout();
          String body = response.getBody();

          return decodePersonBody(body);
      } catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
      }
  }
  
  public class DecodePersonBodyReq {
      String body;
      public DecodePersonBodyReq(String body) { this.body = body; }
  }

  public class MyInfoValue {
      @AuraEnabled public String value;
  }

  public class MyInfoMobileNo {
      @AuraEnabled public String lastupdated;
      @AuraEnabled public String source;
      @AuraEnabled public String classification;
      @AuraEnabled public MyInfoValue areacode;
      @AuraEnabled public MyInfoValue prefix;
      @AuraEnabled public MyInfoValue nbr;

  }

  // TODO: cover more data points
  public class MyInfoResBody {
      @AuraEnabled public MyInfoMobileNo mobileno;
  }

  public class DecodePersonBodyRes {
      String status;
      MyInfoResBody body;
  }

  public static MyInfoResBody decodePersonBody(String body) {
      // TODO: reflect your endpoint
      String herokuAppurl = 'https://YOURENDPOINT.herokuapp.com/decodepersonbody'; 

      HttpRequest req = new HttpRequest();
      req.setEndpoint(herokuAppUrl);
      req.setHeader('Accept', 'application/json');
      req.setHeader('Content-Type','application/json');
      req.setMethod('POST');
      
      DecodePersonBodyReq dpbreq = new DecodePersonBodyReq(body);
      String jsonBody = JSON.serialize(dpbreq);
      req.setBody(jsonBody);

      Http http = new Http();
      HTTPResponse res = http.send(req);
      String responseBody = res.getBody();
      
      DecodePersonBodyRes dpbres = (DecodePersonBodyRes) JSON.deserialize(responseBody, DecodePersonBodyRes.class);
      return dpbres.status == 'OK' ? dpbres.body : null;
  }
}