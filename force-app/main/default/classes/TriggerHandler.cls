public with sharing class TriggerHandler {
    public static void handleBeforeInsert(List<Tweet__c> newTweets) {
    Map<Id, DateTime> latestTweetDateByContact = new Map<Id, DateTime>();
    List<String> tweetTexts = new List<String>();

    for (Tweet__c t : newTweets) {
            if (t.Tweet_Text__c != null) {
                tweetTexts.add(t.Tweet_Text__c);
            }

            if (t.Contact__c != null && t.Tweet_Date__c != null) {
                if (!latestTweetDateByContact.containsKey(t.Contact__c) ||
                    t.Tweet_Date__c > latestTweetDateByContact.get(t.Contact__c)) {
                    latestTweetDateByContact.put(t.Contact__c, t.Tweet_Date__c);
                }
            }
        }

        List<Contact> contactsToUpdate = new List<Contact>();
        for (Id contactId : latestTweetDateByContact.keySet()) {
            contactsToUpdate.add(new Contact(
                Id = contactId,
                Last_Tweet_Post_Date__c = latestTweetDateByContact.get(contactId).date()
            ));
        }

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
        if (!newTweets.isEmpty()) {
            System.enqueueJob(new CreateTweetsJob(newTweets));
        }
    }
    public static void handleAfterDelete(List<Tweet__c> oldTweets) {
        List<String> tweetIds = new List<String>();
        for (Tweet__c t : oldTweets) {
            if (t.Tweet_ID__c != null) {
                tweetIds.add(t.Tweet_ID__c);
            }
        }

        if (!tweetIds.isEmpty()) {
            System.enqueueJob(new DeleteTweetsJob(tweetIds));
        }
    }
}