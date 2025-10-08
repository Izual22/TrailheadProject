@isTest
private class SetviceTest {

    // Test setup: Create mock Twitter auth data
    @testSetup
    static void setupAuth() {
        TwitterAuth__c auth = new TwitterAuth__c(
            API_Key__c = 'key',
            API_Secret__c = 'secret',
            Access_Token__c = 'token',
            Access_Token_Secret__c = 'token_secret'
        );
        insert auth;
    }

    // ✅ Success case: createTweet
    @isTest
    static void testCreateTweetSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockCreateTweetSuccess());

        Test.startTest();
        String tweetId = TwitterService.createTweet('Hello Twitter!');
        Test.stopTest();

        System.assertEquals('987654321', tweetId, 'Tweet ID should match mock response');
    }

    // ❌ Failure case: createTweet (simulate error)
    @isTest
    static void testCreateTweetFailure() {
        Test.setMock(HttpCalloutMock.class, new MockCreateTweetFailure());

        try {
            Test.startTest();
            TwitterService.createTweet('Fail this tweet');
            Test.stopTest();
            System.assert(false, 'Expected CalloutException');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Error creating tweet'), 'Should throw callout exception');
        }
    }

    // ✅ Success case: deleteTweet
    @isTest
    static void testDeleteTweetSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockDeleteTweetSuccess());

        Test.startTest();
        TwitterService.deleteTweet('123456');
        Test.stopTest();

        System.assert(true, 'deleteTweet should complete without exception');
    }

    // ❌ Failure case: deleteTweet
    @isTest
    static void testDeleteTweetFailure() {
        Test.setMock(HttpCalloutMock.class, new MockDeleteTweetFailure());

        try {
            Test.startTest();
            TwitterService.deleteTweet('fail_id');
            Test.stopTest();
            System.assert(false, 'Expected CalloutException');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Error deleting tweet'));
        }
    }

    // ✅ Success case: getTweetsByHandle
    @isTest
    static void testGetTweetsByHandleSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockGetTweetsSuccess());

        Test.startTest();
        List<Map<String, Object>> tweets = TwitterService.getTweetsByHandle('mockhandle');
        Test.stopTest();

        System.assertEquals(2, tweets.size(), 'Should return two tweets');
        System.assertEquals('tweet-id-1', tweets[0].get('id'));
    }

    // ❌ Failure case: user not found
    @isTest
    static void testGetTweetsUserFail() {
        Test.setMock(HttpCalloutMock.class, new MockUserFetchFailure());

        try {
            TwitterService.getTweetsByHandle('failhandle');
            System.assert(false, 'Expected CalloutException');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Error fetching user'));
        }
    }

    // ❌ Failure case: tweet fetch fails
    @isTest
    static void testGetTweetsFetchFail() {
        Test.setMock(HttpCalloutMock.class, new MockTweetFetchFailure());

        try {
            TwitterService.getTweetsByHandle('mockhandle');
            System.assert(false, 'Expected CalloutException');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Error fetching tweets'));
        }
    }

    // === Mocks ===

    private class MockCreateTweetSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setBody('{"data": {"id": "987654321"}}');
            return res;
        }
    }

    private class MockCreateTweetFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error": "Bad request"}');
            return res;
        }
    }

    private class MockDeleteTweetSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data": {"deleted": true}}');
            return res;
        }
    }

    private class MockDeleteTweetFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error": "Server error"}');
            return res;
        }
    }

    private class MockGetTweetsSuccess implements HttpCalloutMock {
        private Integer callCount = 0;

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('/users/by/username/')) {
                res.setStatusCode(200);
                res.setBody('{"data": {"id": "mockUserId"}}');
            } else if (req.getEndpoint().contains('/users/mockUserId/tweets')) {
                res.setStatusCode(200);
                res.setBody('{"data": [' +
                    '{"id": "tweet-id-1", "text": "First tweet"},' +
                    '{"id": "tweet-id-2", "text": "Second tweet"}' +
                ']}');
            } else {
                res.setStatusCode(404);
                res.setBody('{"error": "Not found"}');
            }

            return res;
        }
    }

    private class MockUserFetchFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            res.setBody('{"error": "User not found"}');
            return res;
        }
    }

    private class MockTweetFetchFailure implements HttpCalloutMock {
        private Boolean userFetched = false;

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();

            if (req.getEndpoint().contains('/users/by/username/')) {
                res.setStatusCode(200);
                res.setBody('{"data": {"id": "mockUserId"}}');
            } else if (req.getEndpoint().contains('/users/mockUserId/tweets')) {
                res.setStatusCode(500);
                res.setBody('{"error": "Fetch failed"}');
            }

            return res;
        }
    }
}
