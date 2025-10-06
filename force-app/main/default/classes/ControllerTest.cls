@IsTest
public class ControllerTest {

    private static TweetController.TweetWrapper createTweetWrapper(String id, String text, String createdAt) {
        TweetController.TweetWrapper tw = new TweetController.TweetWrapper();
        tw.id = id;
        tw.text = text;
        tw.createdAt = createdAt;
        return tw;
    }

    @IsTest
    static void testGetTweetsByContact() {
        Contact c = new Contact(LastName = 'Test');
        insert c;

        Tweet__c tweet1 = new Tweet__c(Contact__c = c.Id, Tweet_Text__c = 'Test tweet 1', Tweet_Date__c = DateTime.now());
        insert tweet1;

        Test.startTest();
        List<Tweet__c> tweets = TweetController.getTweetsByContact(c.Id);
        Test.stopTest();

        System.assert(!tweets.isEmpty(), 'Tweets should be returned');
        System.assertEquals(tweet1.Tweet_Text__c, tweets[0].Tweet_Text__c);
    }

    @IsTest
    static void testSync_NoTwitterHandle() {
        Contact c = new Contact(LastName = 'NoHandle');
        insert c;

        try {
            TweetController.sync(c.Id);
            System.assert(false, 'Expected exception for missing Twitter handle');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('No Twitter handle found'));
        }
    }

    @IsTest
    static void testDeleteTweet() {
        Contact c = new Contact(LastName = 'TestDelete');
        insert c;

        Tweet__c tweet = new Tweet__c(Contact__c = c.Id, Tweet_Text__c = 'To delete', Tweet_ID__c = '12345', Tweet_Date__c = DateTime.now());
        insert tweet;
       Test.setMock(HttpCalloutMock.class, new MockDeleteTweetCallout());

        Test.startTest();
        TweetController.deleteTweet(tweet.Tweet_ID__c);
        Test.stopTest();

        Integer countTweets = [SELECT COUNT() FROM Tweet__c WHERE Id = :tweet.Id];
        System.assertEquals(0, countTweets, 'Tweet should be deleted');
    }

    private class MockDeleteTweetCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data": {"deleted": true}}');
            return res;
        }
    }
}
