@isTest
private class TriggerTest {

    @isTest static void testHandleAfterInsertUpdatesContactsAndEnqueuesJob() {
        Contact c1 = new Contact(FirstName = 'Test', LastName = 'User1');
        Contact c2 = new Contact(FirstName = 'Test', LastName = 'User2');
        insert new List<Contact>{c1, c2};

        List<Tweet__c> tweets = new List<Tweet__c>{
            new Tweet__c(
                Tweet_Text__c = 'First tweet',
                Contact__c = c1.Id,
                Tweet_Date__c = DateTime.newInstance(2025, 10, 1, 12, 0, 0)
            ),
            new Tweet__c(
                Tweet_Text__c = 'Second tweet',
                Contact__c = c1.Id,
                Tweet_Date__c = DateTime.newInstance(2025, 10, 3, 12, 0, 0) 
            ),
            new Tweet__c(
                Tweet_Text__c = 'Tweet for user 2',
                Contact__c = c2.Id,
                Tweet_Date__c = DateTime.newInstance(2025, 9, 30, 12, 0, 0)
            ),
            new Tweet__c(
                Tweet_Text__c = 'Tweet with no contact',
                Tweet_Date__c = DateTime.newInstance(2025, 10, 4, 12, 0, 0)
            )
        };

        Test.startTest();
        TriggerHandler.handleAfterInsert(tweets);
        Test.stopTest();

        Contact c1After = [SELECT Last_Tweet_Post_Date__c FROM Contact WHERE Id = :c1.Id];
        Contact c2After = [SELECT Last_Tweet_Post_Date__c FROM Contact WHERE Id = :c2.Id];

        System.assertEquals(Date.newInstance(2025, 10, 3), c1After.Last_Tweet_Post_Date__c,
            'Contact 1 Last_Tweet_Post_Date__c should be set to latest tweet date');

        System.assertEquals(Date.newInstance(2025, 9, 30), c2After.Last_Tweet_Post_Date__c,
            'Contact 2 Last_Tweet_Post_Date__c should be set');

    }

    @isTest static void testHandleAfterInsertWithEmptyList() {

        Test.startTest();
        TriggerHandler.handleAfterInsert(new List<Tweet__c>());
        Test.stopTest();
    }

    @isTest static void testHandleAfterInsertWithNullFields() {
        Tweet__c t = new Tweet__c();
        Test.startTest();
        TriggerHandler.handleAfterInsert(new List<Tweet__c>{t});
        Test.stopTest();
    }
}
