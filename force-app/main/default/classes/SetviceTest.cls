@IsTest
private class SetviceTest {

    private class CreateTweetMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(201);
            res.setBody('{"data":{"id":"12345","created_at":"2025-10-05T10:00:00Z"}}');
            return res;
        }
    }
    private class TweetFailMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('Bad request');
            return res;
        }
    }

    private class DeleteTweetMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{}'); // Empty body on successful delete
            return res;
        }
    }
    private class GetTweetsByHandleMock implements HttpCalloutMock {
        private Integer callCount = 0;

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (callCount == 0) {
                res.setStatusCode(200);
                res.setBody('{"data":{"id":"user123","username":"testuser"}}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"data":[{"id":"tweet1","text":"Hello world","created_at":"2025-10-05T10:00:00Z"},{"id":"tweet2","text":"Another tweet","created_at":"2025-10-05T11:00:00Z"}]}');
            }
            callCount++;
            return res;
        }
    }


    @IsTest
    static void testDeleteTweet() {
        Test.setMock(HttpCalloutMock.class, new DeleteTweetMock());

        TwitterService.deleteTweet('12345');
    }

    @IsTest
    static void testGetTweetsByHandle() {
        Test.setMock(HttpCalloutMock.class, new GetTweetsByHandleMock());

        List<Map<String, Object>> tweets = TwitterService.getTweetsByHandle('testuser');

        System.assertEquals(2, tweets.size());
        System.assertEquals('tweet1', tweets[0].get('id'));
        System.assertEquals('Hello world', tweets[0].get('text'));
    }

    @IsTest
    static void testDeleteTweet_calloutException() {
        Test.setMock(HttpCalloutMock.class,new TweetFailMock());
        try {
            TwitterService.deleteTweet('badid');
            System.assert(false, 'Expected exception not thrown');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Error deleting tweet'));
        }
    }
}
