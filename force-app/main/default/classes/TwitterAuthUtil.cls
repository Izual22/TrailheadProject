public class TwitterAuthUtil {
    public static Map<String, String> getAuthHeaders(String httpMethod, String baseUrl, Map<String, String> additionalParams) {
        TwitterAuth__c auth = TwitterAuth__c.getOrgDefaults();


        String oauth_consumer_key = auth.API_Key__c;
        String oauth_token = auth.Access_Token__c;
        String oauth_signature_method = 'HMAC-SHA1';
        String oauth_timestamp = String.valueOf(DateTime.now().getTime() / 1000);
        String oauth_nonce = String.valueOf(Crypto.getRandomLong());
        String oauth_version = '1.0';

        Map<String, String> params = new Map<String, String>{
            'oauth_consumer_key' => oauth_consumer_key,
            'oauth_token' => oauth_token,
            'oauth_signature_method' => oauth_signature_method,
            'oauth_timestamp' => oauth_timestamp,
            'oauth_nonce' => oauth_nonce,
            'oauth_version' => oauth_version
        };

        if (additionalParams != null) {
            params.putAll(additionalParams);
        }

        // Sort parameters
        List<String> keys = new List<String>(params.keySet());
        keys.sort();
        List<String> paramList = new List<String>();
        for (String key : keys) {
            paramList.add(EncodingUtil.urlEncode(key, 'UTF-8') + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8'));
        }
        String paramString = String.join(paramList, '&');

        String baseString = httpMethod.toUpperCase() + '&' +
            EncodingUtil.urlEncode(baseUrl, 'UTF-8') + '&' +
            EncodingUtil.urlEncode(paramString, 'UTF-8');

        String signingKey = EncodingUtil.urlEncode(auth.API_Secret__c, 'UTF-8') + '&' + EncodingUtil.urlEncode(auth.Access_Token_Secret__c, 'UTF-8');
        Blob signature = Crypto.generateMac('HmacSHA1', Blob.valueOf(baseString), Blob.valueOf(signingKey));
        String oauth_signature = EncodingUtil.urlEncode(EncodingUtil.base64Encode(signature), 'UTF-8');

        params.put('oauth_signature', oauth_signature);

        // Build the OAuth header
        List<String> headerParts = new List<String>();
        for (String key : params.keySet()) {
            if (key.startsWith('oauth_')) {
                headerParts.add(key + '="' + params.get(key) + '"');
            }
        }

        String authHeader = 'OAuth ' + String.join(headerParts, ', ');

        return new Map<String, String>{ 'Authorization' => authHeader };
    }
}