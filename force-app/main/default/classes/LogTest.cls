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
private class LogTest {

    @isTest
    static void  testInsert() {
        Exception fakeException;
        try {
            Integer i = 1 / 0;
        } catch (Exception ex) {
            fakeException = ex;
        }
        Test.startTest();
        LogService.logError(fakeException, 'This is a test-friendly error message', 'LogServiceTest');
        Test.stopTest();
        List<Log__c> logs = [SELECT Message__c, StackTrace__c, User_Friendly_Message__c, Class_Name__c FROM Log__c];
        System.assertEquals(1, logs.size(), 'One log entry should have been inserted');
        
        Log__c log = logs[0];
        System.assert(log.Message__c.contains('/ by zero'), 'Message should contain division error');
        System.assert(log.StackTrace__c != null && log.StackTrace__c.contains('LogServiceTest'), 'Stack trace should reference the test class');
        System.assertEquals('This is a test-friendly error message', log.User_Friendly_Message__c);
        System.assertEquals('LogServiceTest', log.Class_Name__c);
    }
    @isTest
    static void testFail(){
        Exception fakeException=new DmlException('Test failure');
        Test.startTest();
        try {
            Exception ex = new DmlException('x'.repeat(100000));
            LogService.logError(ex, 'Should fail to insert', 'LogServiceTest');
        }catch(Exception unexpectedEx){
            System.assert(false, 'Logging should not throw an exception');
        }
        Test.stopTest();
    }
}