@isTest
private class ControllerTest {

    @testSetup
    static void setupData() {
        TwitterAuth__c auth = new TwitterAuth__c(
            API_Key__c = 'key',
            API_Secret__c = 'secret',
            Access_Token__c = 'token',
            Access_Token_Secret__c = 'token_secret'
        );
        insert auth;
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Twitter_Handle__c = 'mockhandle'
        );
        insert c;

        Tweet__c t = new Tweet__c(
            Contact__c = c.Id,
            Tweet_ID__c = '12345',
            Tweet_Text__c = 'Old Tweet',
            Tweet_Date__c = DateTime.now().addDays(-1)
        );
        insert t;
    }

    @isTest
    static void testGetTweetsByContact() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        List<Tweet__c> tweets = TweetController.getTweetsByContact(c.Id);
        System.assert(tweets != null);
    }

    @isTest
    static void testSyncWithTweets() {
        Contact c = [SELECT Id FROM Contact WHERE Twitter_Handle__c != null LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new TwitterCalloutMock());
        Test.startTest();
        String result = TweetController.sync(c.Id);
        Test.stopTest();

        System.assert(result.contains('new'), 'Expected new tweets in result');
        List<Tweet__c> tweets = [SELECT Id FROM Tweet__c WHERE Contact__c = :c.Id];
        System.assert(tweets.size() >= 2, 'Expected tweets to be inserted');
    }

    @isTest
    static void testSyncNoHandle() {
        Contact c = new Contact(
            FirstName = 'No',
            LastName = 'Handle'
        );
        insert c;

        try {
            TweetController.sync(c.Id);
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assertEquals('No Twitter handle found for this contact.', e.getMessage());
        }
    }

    @isTest
    static void testSyncNoTweetsFound() {
        Test.setMock(HttpCalloutMock.class, new TwitterCalloutMockEmpty());

        Contact c = new Contact(
            FirstName = 'Empty',
            LastName = 'Tweets',
            Twitter_Handle__c = 'emptyhandle'
        );
        insert c;

        Test.startTest();
        String result = TweetController.sync(c.Id);
        Test.stopTest();

        System.assertEquals('No tweets found.', result);
    }

    @isTest
    static void testDeleteTweet() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Tweet__c tweet = new Tweet__c(
            Contact__c = c.Id,
            Tweet_ID__c = '99999',
            Tweet_Text__c = 'To be deleted',
            Tweet_Date__c = DateTime.now()
        );
        insert tweet;

        Test.setMock(HttpCalloutMock.class, new TwitterCalloutMock());

        Test.startTest();
        TweetController.deleteTweet(tweet.Id);
        Test.stopTest();

        List<Tweet__c> deleted = [SELECT Id FROM Tweet__c WHERE Id = :tweet.Id];
        System.assertEquals(0, deleted.size(), 'Tweet should be deleted');
    }

    private class TwitterCalloutMockEmpty implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('/users/by/username/')) {
                res.setStatusCode(200);
                res.setBody('{"data": {"id": "mockUserId"}}');
                return res;
            }

            if (req.getEndpoint().contains('/users/mockUserId/tweets')) {
                res.setStatusCode(200);
                res.setBody('{"data": []}');
                return res;
            }

            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }
}
