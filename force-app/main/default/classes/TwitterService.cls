public class TwitterService {

    public static final String API_BASE = 'https://api.twitter.com/2';

    private static HttpRequest buildRequest(String method, String url, Map<String, Object> body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');

        Map<String, String> headers = TwitterAuthUtil.getAuthHeaders(method, url, null);
        for (String key : headers.keySet()) {
            req.setHeader(key, headers.get(key));
        }

        if (body != null) {
            req.setBody(JSON.serialize(body));
        }

        return req;
    }

    public static Map<String, Object> createTweetAnd(String text) {
        try{
        String url = API_BASE + '/tweets';
        Http http = new Http();
        Map<String, Object> body = new Map<String, Object>{ 'text' => text };
        HttpRequest req = buildRequest('POST', url, body);

        HttpResponse res = http.send(req);
        System.debug('Create Tweet Response: ' + res.getBody());
        
        if (res.getStatusCode() != 201 && res.getStatusCode() != 200) {
            throw new CalloutException('Error creating tweet: ' + res.getBody());
        }

        Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> data = (Map<String, Object>) resp.get('data');
        String tweetId = (String) data.get('id');
        String createdAt = (String) data.get('created_at');
        Map<String, Object> result = new Map<String, Object>();
        result.put('id', tweetId);
        result.put('created_at', createdAt);
        return result;
        }
        catch(Exception ex){
            LogService.logError(ex, 'Failed to create tweet', 'TwitterService');
            throw ex;
        }
    }
    public static void createTweet(String text, Tweet__c tweet) {
        try{
        String url = API_BASE + '/tweets';
        Http http = new Http();
        Map<String, Object> body = new Map<String, Object>{ 'text' => text };
        HttpRequest req = buildRequest('POST', url, body);
        HttpResponse res = http.send(req);
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> data = (Map<String, Object>) responseMap.get('data');
        tweet.Tweet_ID__c = (String) data.get('id');
        String createdAt = (String) data.get('created_at');
        tweet.Tweet_Date__c = DateTime.valueOfGmt(createdAt);
        update tweet;
        System.debug('Create Tweet Response: ' + res.getBody());

        if (res.getStatusCode() != 201 && res.getStatusCode() != 200) {
            throw new CalloutException('Error creating tweet: ' + res.getBody());
        }
        }
        catch(Exception ex){
            LogService.logError(ex, 'Failed to create tweet', 'TwitterService');
            throw ex;
        }
    }


    public static void deleteTweet(String tweetId) {
         try {
            String url = API_BASE + '/tweets/' + tweetId;
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod('DELETE');

            Map<String, String> headers = TwitterAuthUtil.getAuthHeaders('DELETE', url, null);
            for (String key : headers.keySet()) {
                req.setHeader(key, headers.get(key));
            }

            HttpResponse res = http.send(req);
            System.debug('Delete Tweet Response: ' + res.getBody());

            if (res.getStatusCode() != 200) {
                throw new CalloutException('Error deleting tweet: ' + res.getBody());
            }

        } catch (Exception ex) {
            LogService.logError(ex, 'Failed to delete tweet', 'TwitterService');
            throw ex;
        }
    }
public static List<Map<String, Object>> getTweetsByHandle(String handle) {
    try {
        String userUrl = API_BASE + '/users/by/username/' + handle;
        Http http = new Http();
        HttpRequest userReq = new HttpRequest();
        userReq.setEndpoint(userUrl);
        userReq.setMethod('GET');

        Map<String, String> headers = TwitterAuthUtil.getAuthHeaders('GET', userUrl, null);
        for (String key : headers.keySet()) {
            userReq.setHeader(key, headers.get(key));
        }

        HttpResponse userRes = http.send(userReq);

        if (userRes.getStatusCode() != 200) {
            throw new CalloutException('Error fetching user: ' + userRes.getBody());
        }

        Map<String, Object> userResp = (Map<String, Object>) JSON.deserializeUntyped(userRes.getBody());
        Map<String, Object> userData = (Map<String, Object>) userResp.get('data');
        String userId = (String) userData.get('id');

        String tweetsUrl = API_BASE + '/users/' + userId + '/tweets';
        HttpRequest tweetsReq = new HttpRequest();
        tweetsReq.setEndpoint(tweetsUrl);
        tweetsReq.setMethod('GET');

        headers = TwitterAuthUtil.getAuthHeaders('GET', tweetsUrl, null);
        for (String key : headers.keySet()) {
            tweetsReq.setHeader(key, headers.get(key));
        }

        HttpResponse tweetsRes = http.send(tweetsReq);

        if (tweetsRes.getStatusCode() != 200) {
            throw new CalloutException('Error fetching tweets: ' + tweetsRes.getBody());
        }

        Map<String, Object> tweetsResp = (Map<String, Object>) JSON.deserializeUntyped(tweetsRes.getBody());
        Object dataObj = tweetsResp.get('data');

        List<Map<String, Object>> rawTweets = new List<Map<String, Object>>();

        if (dataObj instanceof List<Object>) {
            for (Object o : (List<Object>) dataObj) {
                rawTweets.add((Map<String, Object>) o);
            }
        }

        return rawTweets;

    } catch (Exception ex) {
        LogService.logError(ex, 'Failed to fetch tweets for handle: ' + handle, 'TwitterService');
        throw ex;
    }
	}


}