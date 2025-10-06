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
private class DeleteTweetsJobTest {

    private class SuccessfulDeleteMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"data": {"deleted": true}}');
            return res;
        }
    }
    private class FailingDeleteMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setBody('{"error": "Something went wrong"}');
            return res;
        }
    }
    @isTest
    static void success() {
        Test.setMock(HttpCalloutMock.class, new SuccessfulDeleteMock());
        List<String> tweetIds = new List<String>{ '1234567890', '0987654321' };
        Test.startTest();
        System.enqueueJob(new DeleteTweetsJob(tweetIds));
        Test.stopTest();
        System.assert(true, 'DeleteTweetsJob ran successfully with mock');
    }
    @IsTest
    static void failure() {
        Test.setMock(HttpCalloutMock.class, new FailingDeleteMock());
        List<String> tweetIds = new List<String>{ '1234567890', '0987654321' };
        Test.startTest();
        System.enqueueJob(new DeleteTweetsJob(tweetIds));
        Test.stopTest();
        System.Assert.isTrue(false, 'DeleteTweetsJob failed with mock');
    }
}