@IsTest
private class AuthTest {

    @TestSetup
    static void setup() {
        TwitterAuth__c auth = new TwitterAuth__c(
            API_Key__c = 'testApiKey',
            API_Secret__c = 'testApiSecret',
            Access_Token__c = 'testAccessToken',
            Access_Token_Secret__c = 'testAccessTokenSecret'
        );
        insert auth;
    }

    @IsTest
    static void testGetAuthHeaders_basic() {
        Map<String, String> headers = TwitterAuthUtil.getAuthHeaders('GET', 'https://api.twitter.com/1.1/statuses/user_timeline.json', null);

        System.assert(headers.containsKey('Authorization'), 'Authorization header should be present');

        String authHeader = headers.get('Authorization');
        System.debug('Authorization Header: ' + authHeader);
        System.assert(authHeader.contains('oauth_consumer_key="testApiKey"'), 'Should contain consumer key');
        System.assert(authHeader.contains('oauth_token="testAccessToken"'), 'Should contain token');
        System.assert(authHeader.contains('oauth_signature='), 'Should contain oauth_signature');
        System.assert(authHeader.contains('oauth_nonce='), 'Should contain oauth_nonce');
        System.assert(authHeader.contains('oauth_timestamp='), 'Should contain oauth_timestamp');
        System.assert(authHeader.startsWith('OAuth '), 'Header should start with OAuth');
        Pattern p = Pattern.compile('oauth_[a-z_]+="[^"]+"');
        Matcher m = p.matcher(authHeader);
        Integer count = 0;
        while (m.find()) {
            count++;
        }
        System.assert(count >= 6, 'Should have at least 6 OAuth parameters');
    }

    @IsTest
    static void testGetAuthHeaders_withAdditionalParams() {
        Map<String, String> extraParams = new Map<String, String>{
            'status' => 'Hello World!',
            'include_entities' => 'true'
        };

        Map<String, String> headers = TwitterAuthUtil.getAuthHeaders('POST', 'https://api.twitter.com/1.1/statuses/update.json', extraParams);

        System.assert(headers.containsKey('Authorization'), 'Authorization header should be present');

        String authHeader = headers.get('Authorization');

        System.assert(authHeader.contains('oauth_consumer_key="testApiKey"'), 'Should contain consumer key');
        System.assert(authHeader.contains('oauth_token="testAccessToken"'), 'Should contain token');
        System.assert(authHeader.contains('oauth_signature='), 'Should contain oauth_signature');
        System.assert(authHeader.contains('oauth_nonce='), 'Should contain oauth_nonce');
        System.assert(authHeader.contains('oauth_timestamp='), 'Should contain oauth_timestamp');
    }
}