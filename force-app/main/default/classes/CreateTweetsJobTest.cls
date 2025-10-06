/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class CreateTweetsJobTest {

    @isTest
    static void testCreateTweetJobSuccess() {
        Test.setMock(HttpCalloutMock.class, new TwitterCalloutMock());
        Tweet__c tweet = new Tweet__c(
            Name = 'Test Tweet',
            Tweet_Text__c = 'Hello world from test class!'
        );
        insert tweet;
        Test.startTest();
        System.enqueueJob(new CreateTweetsJob(new List<Tweet__c>{ tweet }));
        Test.stopTest();
        Tweet__c updatedTweet = [SELECT Id, Tweet_ID__c, Tweet_Date__c FROM Tweet__c WHERE Id = :tweet.Id];
        System.assertNotEquals(null, updatedTweet.Tweet_ID__c, 'Tweet_ID__c should be set');
        System.assertEquals('1234567890', updatedTweet.Tweet_ID__c, 'Tweet_ID__c should match mocked ID');
         System.assertNotEquals(null, updatedTweet.Tweet_Date__c, 'Tweet_Date__c should be set');
        System.assertEquals(
            DateTime.valueOfGmt('2023-10-05T12:34:56.000Z'),
            updatedTweet.Tweet_Date__c,
            'Tweet_Date__c should match mocked date'
        );
    }
    @isTest
    static void testCreateTweetJobFailure(){
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        Tweet__c tweet = new Tweet__c(
            Name = 'Test Tweet',
            Tweet_Text__c = 'Hello world from test class!'
        );
        insert tweet;
        Test.startTest();
        System.enqueueJob(new CreateTweetsJob(new List<Tweet__c>{ tweet }));
        Test.stopTest();
        Tweet__c failedTweet = [SELECT Id, Tweet_ID__c, Tweet_Date__c FROM Tweet__c WHERE Id = :tweet.Id];

        System.assertEquals(null, failedTweet.Tweet_ID__c, 'Tweet_ID__c should remain null on failure');
        System.assertEquals(null, failedTweet.Tweet_Date__c, 'Tweet_Date__c should remain null on failure');
    }
        private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error": "Internal server error"}');
            return res;
        }
    }
}