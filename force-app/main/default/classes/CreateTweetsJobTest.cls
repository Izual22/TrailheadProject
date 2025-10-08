@isTest
private class CreateTweetsJobTest {

    @testSetup
    static void setupData() {
        TwitterAuth__c auth = new TwitterAuth__c(
            API_Key__c = 'key',
            API_Secret__c = 'secret',
            Access_Token__c = 'token',
            Access_Token_Secret__c = 'token_secret'
        );
        insert auth;
        List<Tweet__c> tweets = new List<Tweet__c>();
        for (Integer i = 0; i < 2; i++) {
            tweets.add(new Tweet__c(
                Name = 'Test Tweet ' + i,
                Tweet_Text__c = 'This is tweet #' + i
            ));
        }
        insert tweets;
    }

    @isTest
    static void testExecuteSuccess() {
        List<Tweet__c> tweets = [SELECT Id, Tweet_Text__c FROM Tweet__c];

        Test.setMock(HttpCalloutMock.class, new MockCreateTweetSuccess());

        Test.startTest();
        System.enqueueJob(new CreateTweetsJob(tweets));
        Test.stopTest();

        List<Tweet__c> updated = [SELECT Id, Tweet_ID__c, Tweet_Date__c FROM Tweet__c];
        for (Tweet__c t : updated) {
            System.assertNotEquals(null, t.Tweet_ID__c, 'Tweet ID should be populated');
            System.assertNotEquals(null, t.Tweet_Date__c, 'Tweet Date should be populated');
        }
    }

    @isTest
    static void testExecuteFailure() {
        List<Tweet__c> tweets = [SELECT Id, Tweet_Text__c FROM Tweet__c];

        Test.setMock(HttpCalloutMock.class, new MockCreateTweetFailure());

        Test.startTest();
        System.enqueueJob(new CreateTweetsJob(tweets));
        Test.stopTest();

        List<Tweet__c> unchanged = [SELECT Tweet_ID__c, Tweet_Date__c FROM Tweet__c];
        for (Tweet__c t : unchanged) {
            System.assertEquals(null, t.Tweet_ID__c);
            System.assertEquals(null, t.Tweet_Date__c);
        }

    }


    private class MockCreateTweetSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data": {"id": "mockTweetId123"}}');
            return res;
        }
    }

    private class MockCreateTweetFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error": "Invalid request"}');
            return res;
        }
    }
}
