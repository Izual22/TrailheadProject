@isTest
private class SetviceTest {

    private class CreateTweetSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data": {"id": "tweet123"}}');
            return res;
        }
    }

    private class CreateTweetFailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Server error"}');
            return res;
        }
    }

    private class DeleteTweetSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data": "deleted"}');
            return res;
        }
    }
    private class DeleteTweetFailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error":"Bad request"}');
            return res;
        }
    }

    private class GetTweetsSuccessMock implements HttpCalloutMock {
        private Integer callCount = 0;
        public HttpResponse respond(HttpRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (callCount == 1) {
                res.setStatusCode(200);
                res.setBody('{"data": {"id": "user123"}}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"data": [{"id": "tweet1", "text": "hello"}, {"id": "tweet2", "text": "world"}]}');
            }
            return res;
        }
    }

    private class GetTweetsUserFailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            res.setBody('{"error":"User not found"}');
            return res;
        }
    }

    private class GetTweetsTweetsFailureMock implements HttpCalloutMock {
        private Integer callCount = 0;
        public HttpResponse respond(HttpRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();
            if (callCount == 1) {
                res.setStatusCode(200);
                res.setBody('{"data": {"id": "user123"}}');
            } else {
                res.setStatusCode(500);
                res.setBody('{"error":"Server error"}');
            }
            return res;
        }
    }

    @isTest static void testCreateTweetSuccess() {
        Test.setMock(HttpCalloutMock.class, new CreateTweetSuccessMock());
        String tweetId = TwitterService.createTweet('Test tweet');
        System.assertEquals('tweet123', tweetId);
    }

    @isTest static void testCreateTweetFailure() {
        Test.setMock(HttpCalloutMock.class, new CreateTweetFailureMock());
        try {
            TwitterService.createTweet('Fail tweet');
            System.assert(false, 'Expected exception not thrown');
        } catch (CalloutException ex) {
            System.assert(ex.getMessage().contains('Error creating tweet'));
        }
    }

    @isTest static void testDeleteTweetSuccess() {
        Test.setMock(HttpCalloutMock.class, new DeleteTweetSuccessMock());
        TwitterService.deleteTweet('tweet123');
    }

    @isTest static void testDeleteTweetFailure() {
        Test.setMock(HttpCalloutMock.class, new DeleteTweetFailureMock());
        try {
            TwitterService.deleteTweet('badtweet');
            System.assert(false, 'Expected exception not thrown');
        } catch (CalloutException ex) {
            System.assert(ex.getMessage().contains('Error deleting tweet'));
        }
    }

    @isTest static void testGetTweetsByHandleSuccess() {
        Test.setMock(HttpCalloutMock.class, new GetTweetsSuccessMock());
        List<Map<String, Object>> tweets = TwitterService.getTweetsByHandle('validhandle');
        System.assertEquals(2, tweets.size());
        System.assertEquals('tweet1', tweets[0].get('id'));
    }

    @isTest static void testGetTweetsByHandleUserFailure() {
        Test.setMock(HttpCalloutMock.class, new GetTweetsUserFailureMock());
        try {
            TwitterService.getTweetsByHandle('invalidhandle');
            System.assert(false, 'Expected exception not thrown');
        } catch (CalloutException ex) {
            System.assert(ex.getMessage().contains('Error fetching user'));
        }
    }

    @isTest static void testGetTweetsByHandleTweetsFailure() {
        Test.setMock(HttpCalloutMock.class, new GetTweetsTweetsFailureMock());
        try {
            TwitterService.getTweetsByHandle('handleWithBadTweets');
            System.assert(false, 'Expected exception not thrown');
        } catch (CalloutException ex) {
            System.assert(ex.getMessage().contains('Error fetching tweets'));
        }
    }
}
