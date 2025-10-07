trigger TweetTrigger on Tweet__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        TriggerHandler.handleAfterInsert(Trigger.new);
    }
}