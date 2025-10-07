@isTest
private class CreateTweetsJobTest {

    private class CreateTweetMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setBody('{"data": {"id": "mockTweetId123"}}');
            return res;
        }
    }
    private class ThrowingMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
        throw new CalloutException('Simulated callout failure');
        }
    }

    @isTest static void testExecuteSuccess() {
        Tweet__c t1 = new Tweet__c(Tweet_Text__c = 'Hello World');
        insert t1;

        Tweet__c t2 = new Tweet__c(Tweet_Text__c = 'Second tweet');
        insert t2;

        List<Tweet__c> tweetsToUpdate = new List<Tweet__c>{
            new Tweet__c(Id = t1.Id, Tweet_Text__c = t1.Tweet_Text__c),
            new Tweet__c(Id = t2.Id, Tweet_Text__c = t2.Tweet_Text__c)
        };

        Test.setMock(HttpCalloutMock.class, new CreateTweetMock());

        Test.startTest();
        CreateTweetsJob job = new CreateTweetsJob(tweetsToUpdate);
        System.enqueueJob(job);
        Test.stopTest();

        List<Tweet__c> updatedTweets = [SELECT Tweet_ID__c, Tweet_Date__c FROM Tweet__c WHERE Id IN :tweetsToUpdate];
        for (Tweet__c t : updatedTweets) {
            System.assertEquals('mockTweetId123', t.Tweet_ID__c, 'Tweet_ID__c should be set by the job');
            System.assertNotEquals(null, t.Tweet_Date__c, 'Tweet_Date__c should be set by the job');
        }
    }

    @isTest static void testExecuteWithCalloutException() {
        Tweet__c t = new Tweet__c(Tweet_Text__c = 'Throw error');
        insert t;

        List<Tweet__c> tweetsToUpdate = new List<Tweet__c>{
            new Tweet__c(Id = t.Id, Tweet_Text__c = t.Tweet_Text__c)
        };

        Test.setMock(HttpCalloutMock.class, new ThrowingMock());

        Test.startTest();
        CreateTweetsJob job = new CreateTweetsJob(tweetsToUpdate);
        System.enqueueJob(job);
        Test.stopTest();

        List<Tweet__c> result = [SELECT Tweet_ID__c FROM Tweet__c WHERE Id = :t.Id];
        System.assertEquals(null, result[0].Tweet_ID__c, 'Tweet_ID__c should remain null due to callout failure');
    }

    @isTest static void testConstructorCopiesTweets() {
        Tweet__c t = new Tweet__c(Tweet_Text__c = 'Copy test');
        insert t;

        List<Tweet__c> tweetsToUpdate = new List<Tweet__c>{t};

        CreateTweetsJob job = new CreateTweetsJob(tweetsToUpdate);
        System.assertNotEquals(null, job);
    }
}
