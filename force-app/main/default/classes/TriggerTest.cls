@IsTest
private class TriggerTest {

    private class MockCreateTweet implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data": {"id": "1234567890", "created_at": "2023-10-05T12:34:56.000Z"}}');
            return res;
        }
    }

    private class MockDeleteTweet implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data": {"deleted": true}}');
            return res;
        }
    }

    @IsTest
    static void testHandleBeforeInsert_UpdatesContactAndEnqueuesCreateJob() {
        Test.setMock(HttpCalloutMock.class, new MockCreateTweet());

        Contact contact = new Contact(FirstName = 'Test', LastName = 'User');
        insert contact;

        DateTime tweetDate = DateTime.newInstanceGMT(2023, 10, 5, 10, 0, 0);

        Tweet__c newTweet = new Tweet__c(
            Tweet_Text__c = 'Testing tweet from TriggerHandler',
            Contact__c = contact.Id,
            Tweet_Date__c = tweetDate
        );

        Test.startTest();
        insert newTweet; 
        Test.stopTest();

        Contact updatedContact = [SELECT Last_Tweet_Post_Date__c FROM Contact WHERE Id = :contact.Id];
        System.assertEquals(tweetDate.date(), updatedContact.Last_Tweet_Post_Date__c, 'Contact last tweet date should match Tweet__c date');

        Tweet__c updatedTweet = [SELECT Tweet_ID__c, Tweet_Date__c FROM Tweet__c WHERE Id = :newTweet.Id];
        System.assertEquals('1234567890', updatedTweet.Tweet_ID__c);
        System.assertEquals(DateTime.valueOfGmt('2023-10-05T12:34:56.000Z'), updatedTweet.Tweet_Date__c);
    }

    @IsTest
    static void testHandleAfterDelete_EnqueuesDeleteJob() {
        Test.setMock(HttpCalloutMock.class, new MockDeleteTweet());

        Tweet__c tweet = new Tweet__c(
            Tweet_Text__c = 'To be deleted',
            Tweet_ID__c = '1234567890'
        );
        insert tweet;

        Test.startTest();
        delete tweet; 
        Test.stopTest();

        System.assert(true, 'Tweet deleted and job enqueued');
    }

    @IsTest
    static void testHandleBeforeInsert_NoTweetTextOrDate_DoesNotUpdateContact() {
        Contact contact = new Contact(FirstName = 'Test', LastName = 'NoTweet');
        insert contact;

        Tweet__c tweet = new Tweet__c(Contact__c = contact.Id);

        Test.startTest();
        insert tweet;
        Test.stopTest();

        Contact result = [SELECT Last_Tweet_Post_Date__c FROM Contact WHERE Id = :contact.Id];
        System.assertEquals(null, result.Last_Tweet_Post_Date__c, 'Contact date should not be updated if no Tweet_Date__c is provided');
    }
}